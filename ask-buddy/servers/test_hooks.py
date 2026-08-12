import os
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parents[1]


class ContextHookTests(unittest.TestCase):
    def run_hook(self, name: str, project: Path) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(PLUGIN_ROOT / "hooks" / name)],
            text=True,
            capture_output=True,
            check=True,
            env={**os.environ, "CLAUDE_PROJECT_DIR": str(project), "CLAUDE_PLUGIN_ROOT": str(PLUGIN_ROOT)},
        )

    def test_session_start_is_read_only_and_does_not_inject_long_term_files(self):
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            result = self.run_hook("session-start.py", project)
            self.assertIn("初始化状态", result.stdout)
            self.assertFalse((project / ".ask-buddy").exists())

            memory = project / ".ask-buddy" / "memory"
            memory.mkdir(parents=True)
            (memory / "profile.md").write_text(
                "# User Profile\n- **Style**: concise\n\n"
                "## PREF-001: expired\n- **directive**: expired-profile\n- **expires_at**: 2020-01-01\n- **status**: active\n\n"
                "## Superseded\n- verbose-old-profile\n",
                encoding="utf-8",
            )
            (memory / "memory.md").write_text(
                "## MEM-001\n- **content**: should-load-on-demand\n- **status**: active\n\n"
                "## MEM-002\n- **content**: obsolete-secret\n- **status**: superseded\n",
                encoding="utf-8",
            )
            second = self.run_hook("session-start.py", project)
            self.assertIn("Style**: concise", second.stdout)
            self.assertIn("memory_search", second.stdout)
            self.assertNotIn("verbose-old-profile", second.stdout)
            self.assertNotIn("expired-profile", second.stdout)
            self.assertNotIn("should-load-on-demand", second.stdout)
            self.assertNotIn("obsolete-secret", second.stdout)

    def test_session_start_rejects_memory_symlink_without_writing_through_it(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            project = base / "project"
            outside = base / "outside"
            (project / ".ask-buddy").mkdir(parents=True)
            outside.mkdir()
            os.symlink(outside, project / ".ask-buddy" / "memory")
            result = self.run_hook("session-start.py", project)
            self.assertIn("已禁用项目记忆", result.stdout)
            self.assertFalse((outside / "daily").exists())

    def test_precompact_rejects_symlinked_checkpoint(self):
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            project = base / "project"
            outside = base / "outside.md"
            state = project / ".ask-buddy"
            state.mkdir(parents=True)
            outside.write_text("untrusted checkpoint", encoding="utf-8")
            os.symlink(outside, state / "session-context.md")
            result = self.run_hook("pre-compact.py", project)
            self.assertEqual(result.stdout, "")

    def test_readonly_guard_allows_memory_file_and_rejects_symlink_paths(self):
        with tempfile.TemporaryDirectory() as temporary:
            project = Path(temporary)
            state = project / ".ask-buddy"
            state.mkdir()
            guard = PLUGIN_ROOT / "hooks" / "scripts" / "readonly-guard.sh"

            allowed = subprocess.run(
                [str(guard)],
                input=json.dumps({"tool_name": "Write", "tool_input": {"file_path": str(state / "memory.md")}, "cwd": str(project)}),
                text=True,
                capture_output=True,
            )
            self.assertEqual(allowed.returncode, 0)

            outside = project / "outside"
            outside.mkdir()
            os.symlink(outside, state / "linked")
            blocked = subprocess.run(
                [str(guard)],
                input=json.dumps({"tool_name": "Write", "tool_input": {"file_path": str(state / "linked" / "memory.md")}, "cwd": str(project)}),
                text=True,
                capture_output=True,
            )
            self.assertEqual(blocked.returncode, 2)
            self.assertIn("符号链接", blocked.stderr)


if __name__ == "__main__":
    unittest.main()
