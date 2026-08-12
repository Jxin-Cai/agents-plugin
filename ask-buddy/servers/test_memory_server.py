import datetime as dt
import importlib.util
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).with_name("memory_server.py")
SPEC = importlib.util.spec_from_file_location("ask_buddy_memory_server", MODULE_PATH)
memory = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(memory)


class MemoryServerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.store = self.root / ".ask-buddy" / "memory"
        (self.store / "daily").mkdir(parents=True)

    def tearDown(self):
        self.temp.cleanup()

    def write(self, relative, content):
        path = self.root / ".ask-buddy" / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")

    def test_search_excludes_pending_and_superseded(self):
        self.write("memory/memory.md", "## MEM-001\n- **content**: 火星计划使用蓝色\n- **status**: active\n\n## MEM-002\n- **content**: 火星计划使用红色\n- **status**: superseded\n")
        self.write("memory/pending.md", "## PENDING-001\n- **proposal**: 火星计划是绝密\n")
        result = memory.search_memory(self.root, "火星计划", 10)
        text = str(result)
        self.assertIn("蓝色", text)
        self.assertNotIn("红色", text)
        self.assertNotIn("绝密", text)

    def test_recent_daily_ranks_above_old_daily(self):
        self.write("memory/daily/2026-08-08.md", "## today\n- **summary**: release phoenix\n")
        self.write("memory/daily/2025-01-01.md", "## old\n- **summary**: release phoenix\n")
        result = memory.search_memory(self.root, "release phoenix", 10, dt.date(2026, 8, 8))
        self.assertEqual(result["results"][0]["path"], ".ask-buddy/memory/daily/2026-08-08.md")

    def test_get_rejects_pending_and_traversal(self):
        self.write("memory/memory.md", "safe")
        self.write("memory/pending.md", "secret")
        with self.assertRaises(memory.MemoryError):
            memory.get_memory(self.root, ".ask-buddy/memory/pending.md")
        with self.assertRaises(memory.MemoryError):
            memory.get_memory(self.root, "../outside.md")

    def test_rejects_symlinked_memory_directory(self):
        outside = self.root / "outside"
        outside.mkdir()
        (self.store / "daily").rmdir()
        self.store.rmdir()
        os.symlink(outside, self.store)
        with self.assertRaises(memory.MemoryError):
            memory.search_memory(self.root, "anything")

    def test_stage_deduplicates_pending_candidates(self):
        args = {"target": "profile", "proposal": "偏好短回答", "reason": "多次纠正", "evidence": "turn 2, turn 8", "confidence": "medium"}
        first = memory.stage_memory(self.root, args)
        second = memory.stage_memory(self.root, args)
        self.assertEqual(first["id"], "PENDING-001")
        self.assertEqual(second["id"], "PENDING-001")
        self.assertTrue(second["duplicate"])
        self.assertFalse(first["active"])
        self.assertFalse((self.store / "profile.md").exists())
        self.assertEqual(stat.S_IMODE((self.root / ".ask-buddy").stat().st_mode), 0o700)
        self.assertEqual(stat.S_IMODE(self.store.stat().st_mode), 0o700)
        self.assertEqual(stat.S_IMODE((self.store / "pending.md").stat().st_mode), 0o600)

    def test_stage_deduplicates_already_active_memory(self):
        args = {"target": "profile", "proposal": "偏好短回答", "reason": "用户明确要求", "evidence": "turn 2", "confidence": "high"}
        first = memory.stage_memory(self.root, args)
        memory.decide_pending(self.root, first["id"], "approve")
        repeated = memory.stage_memory(self.root, args)
        self.assertTrue(repeated["duplicate"])
        self.assertTrue(repeated["active"])
        self.assertEqual(repeated["id"], "PREF-001")
        self.assertEqual(memory.list_pending(self.root)["count"], 0)

    def test_rejected_candidate_id_is_not_reused(self):
        first = memory.stage_memory(self.root, {
            "target": "memory", "proposal": "候选一", "reason": "test", "evidence": "turn 1", "confidence": "low",
        })
        memory.decide_pending(self.root, first["id"], "reject")
        second = memory.stage_memory(self.root, {
            "target": "memory", "proposal": "候选二", "reason": "test", "evidence": "turn 2", "confidence": "low",
        })
        self.assertEqual(second["id"], "PENDING-002")

    def test_stage_flattens_markdown_injection(self):
        args = {"target": "memory", "proposal": "候选\n## PENDING-999", "reason": "test", "evidence": "turn 1", "confidence": "low"}
        memory.stage_memory(self.root, args)
        content = (self.store / "pending.md").read_text(encoding="utf-8")
        self.assertNotIn("\n## PENDING-999", content)

    def test_search_excludes_expired_and_ranks_verified_confidence(self):
        self.write(
            "memory/memory.md",
            "## expired\n- **content**: phoenix expired\n- **expires_at**: 2025-01-01\n\n"
            "## low\n- **content**: phoenix active low\n- **confidence**: low\n\n"
            "## high\n- **content**: phoenix active high\n- **confidence**: high\n- **verified_at**: 2026-08-10\n",
        )
        result = memory.search_memory(self.root, "phoenix", 10, dt.date(2026, 8, 11))
        rendered = json.dumps(result, ensure_ascii=False)
        self.assertNotIn("expired", rendered)
        self.assertIn("high", result["results"][0]["excerpt"])
        self.assertEqual(result["results"][0]["metadata"]["confidence"], "high")

    def test_conflicting_subject_requires_explicit_supersedes(self):
        self.write(
            "memory/memory.md",
            "## MEM-001: color\n- **subject**: project.color\n- **content**: 使用蓝色\n- **status**: active\n",
        )
        staged = memory.stage_memory(self.root, {
            "target": "memory",
            "proposal": "改为红色",
            "reason": "用户更新决定",
            "evidence": "turn 9",
            "confidence": "high",
            "subject": "project.color",
        })
        self.assertEqual(staged["potential_conflicts"], ["MEM-001: color"])
        with self.assertRaisesRegex(memory.MemoryError, "冲突"):
            memory.decide_pending(self.root, staged["id"], "approve")

    def test_approve_supersedes_old_memory_and_preserves_metadata(self):
        self.write(
            "memory/memory.md",
            "## MEM-001: color\n- **subject**: project.color\n- **content**: 使用蓝色\n- **status**: active\n",
        )
        staged = memory.stage_memory(self.root, {
            "target": "memory",
            "proposal": "改为暖色",
            "reason": "用户更新决定",
            "evidence": "turn 9",
            "confidence": "high",
            "source": "user",
            "subject": "project.color",
        })
        decided = memory.decide_pending(
            self.root,
            staged["id"],
            "approve",
            proposal_override="改为红色",
            supersedes_override="MEM-001",
        )
        active = (self.store / "memory.md").read_text(encoding="utf-8")
        self.assertTrue(decided["active"])
        self.assertEqual(decided["id"], "MEM-002")
        self.assertEqual(decided["candidate_id"], staged["id"])
        self.assertIn("status**: superseded", active)
        self.assertIn("## MEM-002: 改为红色", active)
        self.assertIn("content**: 改为红色", active)
        self.assertIn("approved_at", active)
        self.assertEqual(memory.list_pending(self.root)["count"], 0)

    def test_approve_respects_lightweight_capacity_and_keeps_pending(self):
        self.write("memory/profile.md", "# Profile\n" + ("现有偏好 " * 700))
        staged = memory.stage_memory(self.root, {
            "target": "profile",
            "proposal": "偏好简短回答",
            "reason": "用户明确要求",
            "evidence": "turn 3",
            "confidence": "high",
        })
        with self.assertRaisesRegex(memory.MemoryError, "超过 3000 字符"):
            memory.decide_pending(self.root, staged["id"], "approve")
        self.assertEqual(memory.list_pending(self.root)["count"], 1)
        self.assertNotIn("偏好简短回答", (self.store / "profile.md").read_text(encoding="utf-8"))

    def test_learning_stage_is_structured_and_inactive(self):
        staged = memory.learning_stage(self.root, {
            "name": "飞书读取前检查绑定",
            "trigger": "读取飞书数据前",
            "goal": "避免无配置失败",
            "procedure": ["检查 binding status", "缺失时展示二维码"],
            "verification": "读取工具返回真实数据",
            "fallback": "返回明确配置引导",
            "evidence": "test-session",
            "outcome": "success",
            "confidence": "medium",
        })
        pending = memory.list_pending(self.root)
        self.assertFalse(staged["active"])
        self.assertEqual(pending["candidates"][0]["kind"], "procedure")
        self.assertIn("检查 binding status", pending["candidates"][0]["procedure"])
        self.assertEqual(pending["candidates"][0]["verification"], "读取工具返回真实数据")
        self.assertFalse((self.store / "playbook.md").exists())

    def test_learning_approval_renders_canonical_playbook(self):
        staged = memory.learning_stage(self.root, {
            "name": "飞书读取前检查绑定",
            "trigger": "读取飞书数据前",
            "goal": "避免无配置失败",
            "procedure": ["检查 binding status", "缺失时展示二维码"],
            "verification": "读取工具返回真实数据",
            "fallback": "返回明确配置引导",
            "evidence": "test-session",
            "outcome": "success",
            "confidence": "high",
        })
        decided = memory.decide_pending(self.root, staged["id"], "approve")
        playbook = (self.store / "playbook.md").read_text(encoding="utf-8")
        self.assertEqual(decided["id"], "PROC-001")
        self.assertIn("## PROC-001: 飞书读取前检查绑定", playbook)
        self.assertIn("steps**: 1. 检查 binding status | 2. 缺失时展示二维码", playbook)
        self.assertIn("approved_by**: user", playbook)
        self.assertIn("last_used**: never", playbook)
        self.assertNotIn("## PENDING-", playbook)

    def test_stop_hook_stages_only_explicit_user_signal(self):
        transcript = self.root / "transcript.jsonl"
        transcript.write_text(json.dumps({
            "uuid": "u1",
            "type": "user",
            "message": {"role": "user", "content": [{"type": "text", "text": "下次不要一次问我三个问题"}]},
        }, ensure_ascii=False) + "\n", encoding="utf-8")
        hook = MODULE_PATH.parents[1] / "hooks" / "learning-review.py"
        payload = json.dumps({"cwd": str(self.root), "session_id": "session-1", "transcript_path": str(transcript)}, ensure_ascii=False)
        process = subprocess.run([sys.executable, str(hook)], input=payload, text=True, capture_output=True, check=True)
        self.assertIn("PENDING-001", process.stdout)
        self.assertEqual(memory.list_pending(self.root)["count"], 1)
        repeated = subprocess.run([sys.executable, str(hook)], input=payload, text=True, capture_output=True, check=True)
        self.assertEqual(repeated.stdout, "")
        memory.decide_pending(self.root, "PENDING-001", "approve")
        after_approval = subprocess.run([sys.executable, str(hook)], input=payload, text=True, capture_output=True, check=True)
        self.assertEqual(after_approval.stdout, "")
        self.assertEqual(memory.list_pending(self.root)["count"], 0)

    def test_stop_hook_ignores_ordinary_and_sensitive_messages(self):
        transcript = self.root / "transcript.jsonl"
        hook = MODULE_PATH.parents[1] / "hooks" / "learning-review.py"
        payload = json.dumps({"cwd": str(self.root), "session_id": "session-2", "transcript_path": str(transcript)}, ensure_ascii=False)
        for message in (
            "帮我解释一下这个函数",
            "以后市场可能会继续增长，帮我分析一下",
            "下次会议安排在周五",
            "请记住 access_token=top-secret",
            "记住我的密码是 top-secret",
            "记住我的身份证号是 110101199001011234",
            "remember my credit card number is 4111111111111111",
            "请记住我的诊断结果",
        ):
            transcript.write_text(json.dumps({
                "type": "user",
                "message": {"role": "user", "content": [{"type": "text", "text": message}]},
            }, ensure_ascii=False) + "\n", encoding="utf-8")
            process = subprocess.run([sys.executable, str(hook)], input=payload, text=True, capture_output=True, check=True)
            self.assertEqual(process.stdout, "")
        self.assertEqual(memory.list_pending(self.root)["count"], 0)

    def test_stop_hook_extracts_one_explicit_directive_clause(self):
        transcript = self.root / "transcript.jsonl"
        transcript.write_text(json.dumps({
            "type": "user",
            "message": {"role": "user", "content": [{"type": "text", "text": "下次请先给结论，顺便帮我查一下最新资料"}]},
        }, ensure_ascii=False) + "\n", encoding="utf-8")
        hook = MODULE_PATH.parents[1] / "hooks" / "learning-review.py"
        payload = json.dumps({"cwd": str(self.root), "session_id": "session-3", "transcript_path": str(transcript)}, ensure_ascii=False)
        subprocess.run([sys.executable, str(hook)], input=payload, text=True, capture_output=True, check=True)
        candidate = memory.list_pending(self.root)["candidates"][0]
        self.assertEqual(candidate["proposal"], "下次请先给结论")
        self.assertEqual(candidate["target"], "profile")

    def test_malformed_rpc_input_returns_errors_and_server_continues(self):
        payload = (
            '[]\n'
            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":[]}\n'
            '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"memory_status","arguments":[]}}\n'
            '{"jsonrpc":"2.0","id":3,"method":"ping","params":{}}\n'
        )
        process = subprocess.run(
            [sys.executable, str(MODULE_PATH)],
            input=payload,
            text=True,
            capture_output=True,
            env={**os.environ, "ASK_BUDDY_PROJECT_DIR": str(self.root)},
            check=True,
        )
        responses = [json.loads(line) for line in process.stdout.splitlines()]
        self.assertEqual(responses[0]["error"]["code"], -32600)
        self.assertEqual(responses[1]["error"]["code"], -32602)
        self.assertTrue(responses[2]["result"]["isError"])
        self.assertEqual(responses[3]["result"], {})

    def test_stdio_supports_legacy_handshake_and_tools(self):
        payload = (
            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}\n'
            '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n'
        )
        process = subprocess.run([sys.executable, str(MODULE_PATH)], input=payload, text=True, capture_output=True, env={**os.environ, "ASK_BUDDY_PROJECT_DIR": str(self.root)}, check=True)
        lines = process.stdout.splitlines()
        self.assertEqual(len(lines), 2)
        self.assertIn('"protocolVersion":"2025-11-25"', lines[0])
        tools = json.loads(lines[1])["result"]["tools"]
        self.assertEqual(
            {tool["name"] for tool in tools},
            {"memory_status", "memory_search", "memory_get", "memory_stage", "learning_stage", "learning_pending", "learning_decide"},
        )

    def test_modern_discovery_shape(self):
        response = memory.handle({"jsonrpc": "2.0", "id": "d1", "method": "server/discover", "params": {}}, self.root)
        self.assertEqual(response["result"]["resultType"], "complete")
        self.assertEqual(response["result"]["supportedVersions"], ["2026-07-28"])


if __name__ == "__main__":
    unittest.main()
