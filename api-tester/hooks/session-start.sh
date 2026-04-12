#!/bin/bash
# SessionStart hook for api-tester plugin

mkdir -p _api-tests

echo "## API 测试工作台状态"
echo ""
task_count=$(find _api-tests -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 测试任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _api-tests/ 2>/dev/null | head -3 | while read d; do
    state="_api-tests/${d}/meta/test-state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/at/references/api-tester-agent.md"
