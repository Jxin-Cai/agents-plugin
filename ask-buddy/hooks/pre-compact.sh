#!/usr/bin/env bash
# Re-inject the compact working state before Claude Code compresses the session.
# The hook does not create or modify memory; qa-guide maintains session-context.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
CONTEXT_FILE="${PROJECT_DIR}/.ask-buddy/session-context.md"

if [ ! -f "$CONTEXT_FILE" ] || [ -L "${PROJECT_DIR}/.ask-buddy" ]; then
  exit 0
fi

python3 - "$CONTEXT_FILE" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
try:
    content = path.read_text(encoding="utf-8")
except (OSError, UnicodeError):
    raise SystemExit(0)

content = content.strip()
if not content:
    raise SystemExit(0)

limit = 6000
if len(content) > limit:
    content = content[:limit] + "\n[session context truncated]"

print("# Ask Buddy compaction checkpoint")
print("Preserve the active goal, confirmed facts, user corrections, open questions, and source links below. Treat them as working context, not automatically as long-term memory.")
print()
print(content)
PY
