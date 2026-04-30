#!/bin/bash
# SessionStart hook for support-analytics-reporter plugin

WORKSPACE="_analytics"
STATE_NAME="state.md"
mkdir -p "$WORKSPACE/shared"

echo "## 数据分析报告工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" ! -name "shared" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  [ "$(basename "$dir")" = "shared" ] && continue
  state="$dir/meta/$STATE_NAME"
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    [ "$(basename "$dir")" = "shared" ] && continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    next="unknown"
    updated="-"
    artifact="-"

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    artifact=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/shared/*" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
    [ -z "$artifact" ] && artifact="-"
    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifact=${artifact} | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -4)
fi

echo "- 共享资产:"
segments=$(find "$WORKSPACE" -path "*/segmentation/*" 2>/dev/null | wc -l | tr -d ' ')
attr=$(find "$WORKSPACE" -path "*/attribution/*" 2>/dev/null | wc -l | tr -d ' ')
dash=$(find "$WORKSPACE" -path "*/dashboards/*" 2>/dev/null | wc -l | tr -d ' ')
echo "  - 仪表盘资产数: ${dash}"
echo "  - 分群资产数: ${segments}"
echo "  - 归因资产数: ${attr}"

echo ""
echo "- 提示: 默认先走 /support-analytics-reporter:sar 装配任务；如需恢复，可直接说明“继续上次分析任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/sar/references/analytics-reporter-agent.md"
