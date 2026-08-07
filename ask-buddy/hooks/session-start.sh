#!/usr/bin/env bash
# Load a bounded, frozen snapshot of Ask Buddy identity and curated memory.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
STATE_DIR="${PROJECT_DIR}/.ask-buddy"
MEMORY_DIR="${STATE_DIR}/memory"
PROFILE="${MEMORY_DIR}/profile.md"

cat "${CLAUDE_PLUGIN_ROOT}/skills/qa-guide/references/ask-buddy-agent.md"

if [ -L "$STATE_DIR" ]; then
  echo
  echo "Ask Buddy 安全提示：.ask-buddy 是符号链接，已禁用持久记忆。"
  exit 0
fi

# Ask Buddy owns this directory; creating it is the only startup mutation.
mkdir -p "$MEMORY_DIR/daily" "$MEMORY_DIR/_backup"

echo
echo "---"
echo

if [ ! -s "$PROFILE" ]; then
  echo "## 初始化状态"
  echo "尚未建立用户档案。先回答用户当前问题，再在自然停顿处邀请进行轻量初始化；用户拒绝时继续无记忆模式。"
else
  python3 - "$MEMORY_DIR" <<'PY'
from datetime import date, timedelta
from pathlib import Path
import sys

root = Path(sys.argv[1])

def emit(title: str, path: Path, limit: int) -> None:
    if not path.is_file():
        return
    try:
        content = path.read_text(encoding="utf-8").strip()
    except (OSError, UnicodeError):
        return
    if not content:
        return
    if len(content) > limit:
        content = content[:limit] + "\n[bounded snapshot truncated; use Read for the full file]"
    print(f"## {title}\n")
    print(content)
    print()

emit("User model snapshot", root / "profile.md", 3000)
emit("Curated memory snapshot", root / "memory.md", 5000)
emit("Approved playbook snapshot", root / "playbook.md", 3000)

daily = root / "daily"
for offset, label in ((0, "Today working memory"), (1, "Yesterday working memory")):
    day = date.today() - timedelta(days=offset)
    emit(label, daily / f"{day.isoformat()}.md", 1800)

pending = root / "pending.md"
if pending.is_file():
    try:
        text = pending.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        text = ""
    count = text.count("\n## PENDING-") + (1 if text.startswith("## PENDING-") else 0)
    if count:
        print(f"## Memory review\n\n- {count} item(s) await user review in `.ask-buddy/memory/pending.md`. Do not apply them as facts.\n")
PY
fi

if command -v npx >/dev/null 2>&1; then
  echo "- 搜索：OneSearch 已配置；仅在问题需要实时核实时调用"
else
  echo "- 搜索：npx 不可用；联网能力将优雅降级"
fi
