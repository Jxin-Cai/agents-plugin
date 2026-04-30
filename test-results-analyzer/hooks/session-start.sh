#!/bin/bash
# SessionStart hook for test-results-analyzer plugin

WORKSPACE="_test-analysis"
STATE_NAME="state.md"
mkdir -p "$WORKSPACE"

echo "## 测试结果分析工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0
INCONSISTENT=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  state="$dir/meta/$STATE_NAME"
  next=""
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
  fi
  artifact_count=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$state" ] && [ "$next" = "done" ] && [ "$artifact_count" -eq 0 ]; then
    INCONSISTENT=$((INCONSISTENT + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"
[ "$INCONSISTENT" -gt 0 ] && echo "- 状态提醒: ${INCONSISTENT} 个任务状态已完成但缺少阶段产物"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    next="unknown"
    target="-"
    artifacts=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      target=$(grep "^analysis_scope:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/coverage/coverage-*.md >/dev/null 2>&1 && artifacts="${artifacts}COV "
    ls "$dir"/failures/failure-*.md >/dev/null 2>&1 && artifacts="${artifacts}FAIL "
    ls "$dir"/reports/quality-report-*.md >/dev/null 2>&1 && artifacts="${artifacts}RPT "
    [ -z "$artifacts" ] && artifacts="INIT"
    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | scope=${target:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /test-results-analyzer:tra 装配任务；如需恢复，可直接说明“继续上次测试分析任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/tra/references/test-results-analyzer-agent.md"
