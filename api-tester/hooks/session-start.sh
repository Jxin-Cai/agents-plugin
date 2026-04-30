#!/bin/bash
# SessionStart hook for api-tester plugin

WORKSPACE="_api-tests"
mkdir -p "$WORKSPACE"

echo "## API 测试工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 测试任务数: ${TASK_COUNT}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/test-state.md"
    workflow="-"
    next="unknown"
    target="-"
    artifacts=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      target=$(grep "^target_service:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/contracts/contract-*.md >/dev/null 2>&1 && artifacts="${artifacts}CON "
    ls "$dir"/integration/integration-test-plan-*.md >/dev/null 2>&1 && artifacts="${artifacts}INT "
    ls "$dir"/health/health-check-*.md >/dev/null 2>&1 && artifacts="${artifacts}HLT "
    [ -z "$artifacts" ] && artifacts="INIT"

    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | target=${target:--}"
  done < <(ls -dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /api-tester:at 装配任务；如需恢复，可直接说明“继续上次 API 任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/at/references/api-tester-agent.md"
