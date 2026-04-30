#!/bin/bash
# SessionStart hook for performance-benchmarker plugin

WORKSPACE="_performance"
mkdir -p "$WORKSPACE"

echo "## 性能基准测试工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 任务数: ${TASK_COUNT}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/state.md"
    workflow="-"
    next="unknown"
    target="-"
    artifacts=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      target=$(grep "^target_system:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/load-tests/load-test-plan-*.md >/dev/null 2>&1 && artifacts="${artifacts}LOAD "
    ls "$dir"/profiling/profiling-guide-*.md >/dev/null 2>&1 && artifacts="${artifacts}PROF "
    ls "$dir"/reports/optimization-report-*.md >/dev/null 2>&1 && artifacts="${artifacts}RPT "
    [ -z "$artifacts" ] && artifacts="INIT"

    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | target=${target:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /performance-benchmarker:pb 装配任务；如需恢复，可直接说明“继续上次性能任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/pb/references/performance-benchmarker-agent.md"
