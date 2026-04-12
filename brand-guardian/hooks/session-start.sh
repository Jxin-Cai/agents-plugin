#!/bin/bash
# SessionStart hook for brand-guardian plugin

mkdir -p _brand-review

echo "## 品牌守护者工作台状态"
echo ""
task_count=$(find _brand-review -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _brand-review/ 2>/dev/null | head -3 | while read d; do
    state="_brand-review/${d}/meta/state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/bg/references/brand-guardian-agent.md"
