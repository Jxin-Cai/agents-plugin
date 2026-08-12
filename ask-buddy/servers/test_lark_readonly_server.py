import importlib.util
import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).with_name("lark_readonly_server.py")
SPEC = importlib.util.spec_from_file_location("ask_buddy_lark_server", MODULE_PATH)
lark = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(lark)


class LarkReadonlyServerTests(unittest.TestCase):
    @mock.patch.object(lark, "run_cli", return_value="[]")
    def test_agenda_builds_read_only_command(self, run):
        lark.agenda({"start": "2026-08-08", "end": "2026-08-09"})
        run.assert_called_once_with(["calendar", "+agenda", "--as", "user", "--format", "json", "--start", "2026-08-08", "--end", "2026-08-09"])

    @mock.patch.object(lark, "run_cli", return_value="[]")
    def test_tasks_builds_bounded_query(self, run):
        lark.tasks({"query": "发布", "completed": False, "page_limit": 3})
        command = run.call_args.args[0]
        self.assertIn("+get-my-tasks", command)
        self.assertIn("--complete=false", command)
        self.assertNotIn("create", command)

    @mock.patch.object(lark, "run_cli", return_value="[]")
    def test_mail_filter_is_json_encoded_without_shell(self, run):
        lark.mail_search({"sender": "boss@example.com", "unread_only": True, "max_results": 10})
        command = run.call_args.args[0]
        encoded = command[command.index("--filter") + 1]
        self.assertEqual(json.loads(encoded), {"from": ["boss@example.com"], "is_unread": True})

    @mock.patch.object(lark, "run_cli", return_value="{}")
    def test_mail_get_forces_plain_text(self, run):
        lark.mail_get({"message_id": "msg_123"})
        command = run.call_args.args[0]
        self.assertIn("--html=false", command)
        self.assertNotIn("send", command)

    def test_control_characters_are_rejected(self):
        with self.assertRaises(lark.LarkError):
            lark.mail_get({"message_id": "msg\n--confirm-send"})

    def test_non_object_arguments_are_rejected(self):
        with self.assertRaises(lark.LarkError):
            lark.call_tool("feishu_agenda", [])

    def test_malformed_rpc_input_returns_errors_and_server_continues(self):
        payload = (
            '[]\n'
            '{"jsonrpc":"2.0","id":1,"method":"initialize","params":[]}\n'
            '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"feishu_binding_status","arguments":[]}}\n'
            '{"jsonrpc":"2.0","id":3,"method":"ping","params":{}}\n'
        )
        process = subprocess.run(
            [sys.executable, str(MODULE_PATH)],
            input=payload,
            text=True,
            capture_output=True,
            check=True,
        )
        responses = [json.loads(line) for line in process.stdout.splitlines()]
        self.assertEqual(responses[0]["error"]["code"], -32600)
        self.assertEqual(responses[1]["error"]["code"], -32602)
        self.assertTrue(responses[2]["result"]["isError"])
        self.assertEqual(responses[3]["result"], {})

    def test_only_four_tools_are_exposed(self):
        names = {tool["name"] for tool in lark.TOOLS}
        self.assertTrue({"feishu_agenda", "feishu_tasks", "feishu_mail_search", "feishu_mail_get"}.issubset(names))
        self.assertTrue({"feishu_freebusy", "feishu_binding_preflight", "feishu_binding_status", "feishu_binding_start", "feishu_binding_complete"}.issubset(names))
        self.assertTrue(all(tool["annotations"]["destructiveHint"] is False for tool in lark.TOOLS))

    def test_legacy_and_modern_protocol_shapes(self):
        legacy = lark.handle({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25"}})
        modern = lark.handle({"jsonrpc": "2.0", "id": 2, "method": "server/discover", "params": {}})
        self.assertEqual(legacy["result"]["protocolVersion"], "2025-11-25")
        self.assertEqual(modern["result"]["supportedVersions"], ["2026-07-28"])

    def test_project_env_is_atomic_owner_only_and_preserves_unrelated_values(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            env_file = root / ".ask-buddy" / ".env"
            env_file.parent.mkdir()
            env_file.write_text("UNRELATED_SETTING=keep\nASK_BUDDY_LARK_APP_SECRET=never-returned\n", encoding="utf-8")
            os.chmod(env_file, 0o600)
            lark.save_project_env({"ASK_BUDDY_LARK_BINDING_STATUS": "bound"}, root)
            content = env_file.read_text(encoding="utf-8")
            self.assertIn("UNRELATED_SETTING=keep", content)
            self.assertIn("ASK_BUDDY_LARK_APP_SECRET=never-returned", content)
            self.assertIn("ASK_BUDDY_LARK_BINDING_STATUS=bound", content)
            self.assertEqual(stat.S_IMODE(env_file.stat().st_mode), 0o600)
            status = lark.binding_status(root=root)
            self.assertNotIn("never-returned", json.dumps(status, ensure_ascii=False))
            gitignore = (root / ".ask-buddy" / ".gitignore").read_text(encoding="utf-8")
            self.assertIn(".env", gitignore.splitlines())
            self.assertIn(".feishu-qr-*", gitignore.splitlines())

    def test_project_env_rejects_symlinked_storage(self):
        with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryDirectory() as outside:
            root = Path(directory)
            (root / ".ask-buddy").symlink_to(Path(outside), target_is_directory=True)
            with self.assertRaisesRegex(lark.BindingError, "符号链接"):
                lark.save_project_env({"ASK_BUDDY_LARK_BINDING_STATUS": "bound"}, root)

    @mock.patch.object(lark, "cli_prefix", return_value=["lark-cli"])
    @mock.patch.object(lark, "run_cli", side_effect=lark.LarkError("config missing"))
    def test_preflight_returns_structured_missing_config(self, run, prefix):
        with tempfile.TemporaryDirectory() as directory:
            result = lark.preflight(root=Path(directory))
        self.assertFalse(result["ok"])
        self.assertEqual(result["code"], "MISSING_CONFIG")
        self.assertTrue(any("config init" in item for item in result["guidance"]))

    def test_binding_split_flow_keeps_device_code_out_of_metadata(self):
        png = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        outputs = [
            json.dumps({"device_code": "device-secret", "verification_uri_complete": "https://example.invalid/qr?code=device-secret"}),
            "data:image/png;base64," + png,
            "{}",
            json.dumps({
                "status": "bound",
                "app_id": "cli_app_id",
                "open_id": "ou_user",
                "access_token": "access-secret",
                "refresh_token": "refresh-secret",
            }),
        ]
        with tempfile.TemporaryDirectory() as directory, mock.patch.object(lark, "preflight", return_value={"ok": True}), mock.patch.object(lark, "run_cli", side_effect=outputs) as run:
            root = Path(directory)
            started = lark.binding_start(root=root)
            completed = lark.binding_complete({"binding_id": started["binding_id"]}, root=root)
            self.assertEqual(started["qr_image"]["mimeType"], "image/png")
            self.assertTrue(completed["bound"])
            metadata = (root / ".ask-buddy" / ".env").read_text(encoding="utf-8")
            self.assertNotIn("device-secret", metadata)
            self.assertNotIn("access-secret", metadata)
            self.assertNotIn("refresh-secret", metadata)
            self.assertIn("ASK_BUDDY_LARK_APP_ID=cli_app_id", metadata)
            self.assertIn("ASK_BUDDY_LARK_USER_OPEN_ID=ou_user", metadata)
            commands = [call.args[0] for call in run.call_args_list]
            self.assertEqual(commands[0], ["auth", "login", "--domain", "calendar,task,mail", "--recommend", "--no-wait", "--json"])
            self.assertEqual(commands[1][0:3], ["auth", "qrcode", "https://example.invalid/qr?code=device-secret"])
            self.assertEqual(commands[2][0:4], ["auth", "login", "--device-code", "device-secret"])
            self.assertEqual(commands[3], ["auth", "status", "--json", "--verify"])

    def test_binding_start_returns_mcp_image_without_device_code_field(self):
        output = {
            "status": "pending",
            "binding_id": "binding-public-id",
            "verification_url": "https://example.invalid/authorize",
            "qr_image": {"type": "image", "mimeType": "image/png", "data": "aW1hZ2U="},
        }
        request = {
            "jsonrpc": "2.0",
            "id": 7,
            "method": "tools/call",
            "params": {"name": "feishu_binding_start", "arguments": {}},
        }
        with mock.patch.object(lark, "call_tool", return_value=output):
            response = lark.handle(request)
        content = response["result"]["content"]
        self.assertEqual([item["type"] for item in content], ["text", "image"])
        self.assertNotIn("device_code", content[0]["text"])
        self.assertEqual(content[1]["mimeType"], "image/png")

    def test_expired_device_code_is_removed_from_memory(self):
        lark._PENDING_BINDINGS["expired"] = {
            "device_code": "device-secret",
            "created_at": "1",
        }
        lark._prune_pending_bindings(now=1 + lark.BINDING_TTL_SECONDS)
        self.assertNotIn("expired", lark._PENDING_BINDINGS)

    def test_data_tools_require_project_binding_and_verified_auth(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with mock.patch.object(lark, "project_root", return_value=root), mock.patch.object(
                lark,
                "preflight",
                return_value={"ok": True, "checks": {"verified": False}},
            ):
                with self.assertRaisesRegex(lark.BindingError, "二维码绑定"):
                    lark.call_tool("feishu_agenda", {})

            lark.save_project_env({"ASK_BUDDY_LARK_BINDING_STATUS": "bound"}, root)
            with mock.patch.object(lark, "project_root", return_value=root), mock.patch.object(
                lark,
                "preflight",
                return_value={"ok": True, "checks": {"verified": False}},
            ):
                with self.assertRaisesRegex(lark.BindingError, "已过期"):
                    lark.call_tool("feishu_tasks", {})

            with mock.patch.object(lark, "project_root", return_value=root), mock.patch.object(
                lark,
                "preflight",
                return_value={"ok": True, "checks": {"verified": True}},
            ), mock.patch.object(lark, "agenda", return_value="[]") as agenda:
                self.assertEqual(lark.call_tool("feishu_agenda", {}), "[]")
                agenda.assert_called_once_with({})

    @mock.patch.object(lark, "run_cli", return_value="[]")
    def test_freebusy_is_read_only_and_bounded(self, run):
        lark.freebusy({
            "start": "2026-08-10T09:00:00+08:00",
            "end": "2026-08-10T18:00:00+08:00",
            "emails": ["owner@example.com"],
        })
        command = run.call_args.args[0]
        self.assertEqual(command[:2], ["calendar", "+freebusy"])
        self.assertIn("owner@example.com", command)
        self.assertNotIn("create", command)


if __name__ == "__main__":
    unittest.main()
