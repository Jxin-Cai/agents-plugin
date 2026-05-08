#!/bin/bash
# PreToolUse hook: block e2e artifact writes outside .e2e-tests
# This is a mechanism-level guard. SKILL.md instructions guide the model; this hook prevents common tool-level leaks.

HOOK_INPUT=$(cat)
HOOK_INPUT="$HOOK_INPUT" python3 - <<'PY'
import json
import os
import re
import sys

try:
    payload = json.loads(os.environ.get("HOOK_INPUT") or "{}")
except Exception:
    sys.exit(0)

tool_name = payload.get("tool_name", "")
tool_input = payload.get("tool_input") or {}

cwd = payload.get("cwd") or os.getcwd()
e2e_root = os.path.abspath(os.path.join(cwd, ".e2e-tests"))


def normalize_path(value):
    if not isinstance(value, str) or not value.strip():
        return ""
    value = value.strip()
    if value.startswith("file://"):
        value = value[7:]
    if os.path.isabs(value):
        return os.path.abspath(value)
    return os.path.abspath(os.path.join(cwd, value))


def is_under_e2e(path):
    if not path:
        return False
    path = normalize_path(path)
    return path == e2e_root or path.startswith(e2e_root + os.sep)


def rel(path):
    path = normalize_path(path)
    try:
        return os.path.relpath(path, cwd)
    except Exception:
        return path


def block(reason):
    print(
        "🚫 e2e-tester artifact path guard blocked this tool call.\n"
        f"Reason: {reason}\n\n"
        "All e2e process artifacts must be written under `.e2e-tests/`.\n"
        "Use one of these locations instead:\n"
        "- `.e2e-tests/scenarios/{scenario}/runs/{run}/task.md`\n"
        "- `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/`\n"
        "- `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots/`\n"
        "- `.e2e-tests/shared/automation/`\n"
        "- `.e2e-tests/shared/env/`\n",
        file=sys.stderr,
    )
    sys.exit(2)


ROOT_ARTIFACT_NAMES = {
    "task.md",
    "report.md",
    "test-report.md",
    "evidence.md",
    "console-error.txt",
    "console-full.txt",
}
ROOT_ARTIFACT_DIRS = {"task", "test", "test-results", "temp", "output", "reports", ".playwright-mcp"}
IMAGE_EXTS = {".png", ".jpg", ".jpeg"}
SCRIPT_EXTS = {".spec.ts", ".test.ts"}


def looks_like_leaked_artifact(path):
    if not path or is_under_e2e(path):
        return False, ""

    abs_path = normalize_path(path)
    relative = rel(abs_path)
    parts = relative.split(os.sep)
    basename = os.path.basename(abs_path)
    lower = basename.lower()
    _, ext = os.path.splitext(lower)

    if parts and parts[0] in ROOT_ARTIFACT_DIRS:
        return True, f"`{relative}` is in root-level `{parts[0]}/`, which is reserved for leaked e2e artifacts"

    if len(parts) == 1 and lower in ROOT_ARTIFACT_NAMES:
        return True, f"root-level `{relative}` looks like an e2e process artifact"

    if len(parts) == 1 and ext in IMAGE_EXTS:
        return True, f"root-level screenshot `{relative}` must be saved under `.e2e-tests/.../evidence/.../screenshots/`"

    if lower.startswith("page-") and (ext in IMAGE_EXTS or lower.endswith(".yml") or lower.endswith(".yaml")):
        return True, f"Playwright MCP default artifact `{relative}` must not be emitted outside `.e2e-tests/`"

    if any(lower.endswith(suffix) for suffix in SCRIPT_EXTS):
        return True, f"test script `{relative}` must be saved under `.e2e-tests/shared/automation/`"

    return False, ""


def check_file_path_field(field):
    value = tool_input.get(field)
    if not value:
        return
    leaked, reason = looks_like_leaked_artifact(value)
    if leaked:
        block(reason)


# Direct filesystem write tools.
if tool_name in {"Write", "Edit", "MultiEdit"}:
    check_file_path_field("file_path")

if tool_name == "NotebookEdit":
    check_file_path_field("notebook_path")

# Playwright MCP tools that can write artifacts when filename is provided or omitted.
if tool_name.startswith("mcp__plugin_playwright_playwright__"):
    filename = tool_input.get("filename")
    if tool_name.endswith("browser_take_screenshot"):
        if not filename:
            block("browser_take_screenshot without `filename` lets Playwright MCP create root-level `page-*.png` artifacts")
        if not is_under_e2e(filename):
            block(f"screenshot filename `{filename}` is outside `.e2e-tests/`")
    elif filename:
        if not is_under_e2e(filename):
            block(f"Playwright artifact filename `{filename}` is outside `.e2e-tests/`")

# Bash commands: catch common e2e artifact leaks and Playwright default output.
if tool_name == "Bash":
    command = tool_input.get("command") or ""

    # `npx playwright test` defaults to root test-results unless --output is set.
    if re.search(r"\bnpx\s+playwright\s+test\b", command):
        if "--output=.e2e-tests/" not in command and "--output .e2e-tests/" not in command:
            block("`npx playwright test` must include `--output=.e2e-tests/...` to avoid root `test-results/` leakage")

    # Root artifact directory creation or writes.
    artifact_dir_pattern = r"(?<![\w./-])(?:task|test|test-results|temp|output|reports|\.playwright-mcp)(?:/|\b)"
    if re.search(artifact_dir_pattern, command) and ".e2e-tests/" not in command:
        block("Bash command references a root-level e2e artifact directory without `.e2e-tests/` prefix")

    root_file_pattern = r"(?<![\w./-])(?:task\.md|test-report\.md|report\.md|screenshot[^\s]*\.(?:png|jpg|jpeg)|page-[^\s]*\.(?:png|jpg|jpeg|ya?ml))(?![\w.-])"
    if re.search(root_file_pattern, command) and ".e2e-tests/" not in command:
        block("Bash command references a root-level e2e artifact file without `.e2e-tests/` prefix")

sys.exit(0)
PY
