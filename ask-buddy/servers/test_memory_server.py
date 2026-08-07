import datetime as dt
import importlib.util
import os
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

    def test_stage_only_appends_pending_with_incrementing_ids(self):
        args = {"target": "profile", "proposal": "偏好短回答", "reason": "多次纠正", "evidence": "turn 2, turn 8", "confidence": "medium"}
        first = memory.stage_memory(self.root, args)
        second = memory.stage_memory(self.root, args)
        self.assertEqual(first["id"], "PENDING-001")
        self.assertEqual(second["id"], "PENDING-002")
        self.assertFalse(first["active"])
        self.assertFalse((self.store / "profile.md").exists())

    def test_stage_flattens_markdown_injection(self):
        args = {"target": "memory", "proposal": "候选\n## PENDING-999", "reason": "test", "evidence": "turn 1", "confidence": "low"}
        memory.stage_memory(self.root, args)
        content = (self.store / "pending.md").read_text(encoding="utf-8")
        self.assertNotIn("\n## PENDING-999", content)

    def test_stdio_supports_legacy_handshake_and_tools(self):
        payload = (
            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}\n'
            '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n'
        )
        process = subprocess.run([sys.executable, str(MODULE_PATH)], input=payload, text=True, capture_output=True, env={**os.environ, "ASK_BUDDY_PROJECT_DIR": str(self.root)}, check=True)
        lines = process.stdout.splitlines()
        self.assertEqual(len(lines), 2)
        self.assertIn('"protocolVersion":"2025-11-25"', lines[0])
        self.assertIn('"memory_search"', lines[1])

    def test_modern_discovery_shape(self):
        response = memory.handle({"jsonrpc": "2.0", "id": "d1", "method": "server/discover", "params": {}}, self.root)
        self.assertEqual(response["result"]["resultType"], "complete")
        self.assertEqual(response["result"]["supportedVersions"], ["2026-07-28"])


if __name__ == "__main__":
    unittest.main()
