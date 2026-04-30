#!/bin/bash
# SessionStart hook for growth-hacker plugin

WORKSPACE="_growth-hacking"
STATE_NAME="state.md"
mkdir -p "$WORKSPACE"

echo "## 增长黑客工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0
QUICK=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  state="$dir/meta/$STATE_NAME"
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
    [ "$workflow" = "quick-diagnosis" ] && QUICK=$((QUICK + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"
[ "$QUICK" -gt 0 ] && echo "- 快速体检任务数: ${QUICK}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    metric="-"
    stage="unknown"
    next="unknown"
    status="stale"
    latest_artifact="-"

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      metric=$(grep "^north_star_metric:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    latest_artifact=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
    [ -z "$latest_artifact" ] && latest_artifact="-"
    [ "$next" != "done" ] && status="resumable"
    echo "  - ${name} | workflow=${workflow:-unknown} | metric=${metric:--} | stage=${stage:-unknown} | artifact=${latest_artifact:--} | next=${next:-unknown} | status=${status}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /growth-hacker:gh 装配任务；如需恢复，可直接说明“继续上次增长任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/gh/references/growth-hacker-agent.md"
