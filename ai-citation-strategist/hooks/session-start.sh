#!/bin/bash
# SessionStart hook for ai-citation-strategist plugin

WORKSPACE="_ai-citation"
STATE_NAME="citation-state.md"
mkdir -p "$WORKSPACE"

echo "## AI 引用优化工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0
GAPS=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  state="$dir/meta/$STATE_NAME"
  next=""
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
  fi
  artifact_count=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$state" ] && [ "$artifact_count" -eq 0 ]; then
    GAPS=$((GAPS + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"
[ "$GAPS" -gt 0 ] && echo "- 产物缺口任务数: ${GAPS}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    stage="unknown"
    next="unknown"
    target="-"
    updated="-"
    artifacts=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      target=$(grep "^brand:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/audit/citation-audit-*.md >/dev/null 2>&1 && artifacts="${artifacts}AUD "
    ls "$dir"/analysis/lost-prompt-analysis-*.md >/dev/null 2>&1 && artifacts="${artifacts}ANA "
    ls "$dir"/fix-packs/fix-pack-*.md >/dev/null 2>&1 && artifacts="${artifacts}FIX "
    [ -z "$artifacts" ] && artifacts="INIT"
    echo "  - ${name} | workflow=${workflow:-unknown} | stage=${stage:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | brand=${target:--} | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /ai-citation-strategist:acs 装配任务；如需恢复，可直接说明“继续上次引用优化任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/acs/references/ai-citation-strategist-agent.md"
