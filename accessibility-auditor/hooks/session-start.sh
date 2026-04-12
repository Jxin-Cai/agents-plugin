#!/bin/bash
# SessionStart hook for accessibility-auditor plugin

mkdir -p _accessibility

echo "## 无障碍审计工作台状态"
echo ""
task_count=$(find _accessibility -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 审计任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _accessibility/ 2>/dev/null | head -3 | while read d; do
    state="_accessibility/${d}/meta/audit-state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/aa/references/accessibility-auditor-agent.md"
