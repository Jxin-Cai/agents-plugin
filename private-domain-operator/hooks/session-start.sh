#!/bin/bash
# SessionStart hook for private-domain-operator plugin

WORKSPACE="_private-domain"
STATE_NAME="state.md"
mkdir -p "$WORKSPACE"

echo "## 私域运营工作台状态"
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
    next="unknown"
    completed="[]"
    summary="-"
    missing=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      completed=$(grep "^completed_steps:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    latest_summary=$(find "$dir"/meta -type f -name "*-summary.md" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
    [ -n "$latest_summary" ] && summary="$latest_summary"

    ls "$dir"/ecosystem/* >/dev/null 2>&1 || missing="${missing}ECO "
    ls "$dir"/community/* >/dev/null 2>&1 || missing="${missing}COM "
    ls "$dir"/lifecycle/* >/dev/null 2>&1 || missing="${missing}LIFE "
    ls "$dir"/funnel/* >/dev/null 2>&1 || missing="${missing}FUNNEL "
    [ -z "$missing" ] && missing="-"

    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | completed=${completed:-[]} | missing=[${missing}] | summary=${summary}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /private-domain-operator:pdo 装配任务；如需恢复，可直接说明“继续上次私域任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/pdo/references/private-domain-operator-agent.md"
