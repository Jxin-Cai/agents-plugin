#!/bin/bash
# SessionStart hook for support-infrastructure-maintainer plugin

WORKSPACE="_infrastructure"
STATE_NAME="workbench-state.md"
mkdir -p "$WORKSPACE"

echo "## 基础设施维护工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
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
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    stage="unknown"
    next="unknown"
    updated="-"
    artifact="-"

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    artifact=$(find "$dir" -type f ! -path "*/meta/*" ! -path "*/context/*" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
    [ -z "$artifact" ] && artifact="-"
    echo "  - ${name} | workflow=${workflow:-unknown} | stage=${stage:-unknown} | artifact=${artifact} | next=${next:-unknown} | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /support-infrastructure-maintainer:sim 装配任务；如需恢复，可直接说明“继续上次基础设施任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/sim/references/infrastructure-maintainer-agent.md"
