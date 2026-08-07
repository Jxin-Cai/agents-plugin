import importlib.util
import json
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

    def test_only_four_tools_are_exposed(self):
        names = {tool["name"] for tool in lark.TOOLS}
        self.assertEqual(names, {"feishu_agenda", "feishu_tasks", "feishu_mail_search", "feishu_mail_get"})
        self.assertTrue(all(tool["annotations"]["readOnlyHint"] for tool in lark.TOOLS))

    def test_legacy_and_modern_protocol_shapes(self):
        legacy = lark.handle({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2025-11-25"}})
        modern = lark.handle({"jsonrpc": "2.0", "id": 2, "method": "server/discover", "params": {}})
        self.assertEqual(legacy["result"]["protocolVersion"], "2025-11-25")
        self.assertEqual(modern["result"]["supportedVersions"], ["2026-07-28"])


if __name__ == "__main__":
    unittest.main()
