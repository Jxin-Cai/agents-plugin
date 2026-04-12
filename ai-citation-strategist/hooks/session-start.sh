#!/bin/bash
# SessionStart hook for ai-citation-strategist plugin

mkdir -p _ai-citation

echo "## AI 引用优化工作台状态"
echo ""
task_count=$(find _ai-citation -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 优化任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _ai-citation/ 2>/dev/null | head -3 | while read d; do
    state="_ai-citation/${d}/meta/citation-state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/acs/references/ai-citation-strategist-agent.md"
