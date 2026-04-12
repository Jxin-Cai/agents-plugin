#!/bin/bash
# SessionStart hook for support-analytics-reporter plugin

mkdir -p _analytics

echo "## 数据分析报告工作台状态"
echo ""
task_count=$(find _analytics -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _analytics/ 2>/dev/null | head -3 | while read d; do
    state="_analytics/${d}/meta/state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/sar/references/support-analytics-reporter-agent.md"
