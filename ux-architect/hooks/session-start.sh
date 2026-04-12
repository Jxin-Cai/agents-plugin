#!/bin/bash
# SessionStart hook for ux-architect plugin

mkdir -p _ux-arch

echo "## UX 架构工作台状态"
echo ""
task_count=$(find _ux-arch -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _ux-arch/ 2>/dev/null | head -3 | while read d; do
    state="_ux-arch/${d}/meta/state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/uxa/references/ux-architect-agent.md"
