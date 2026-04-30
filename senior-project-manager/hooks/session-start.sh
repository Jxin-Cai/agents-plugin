#!/bin/bash
# SessionStart hook for senior-project-manager plugin

WORKSPACE="_project-mgmt"
STATE_NAME="state.md"
mkdir -p "$WORKSPACE"

echo "## 高级项目经理工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0
GAPS=0
STALE=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  state="$dir/meta/$STATE_NAME"
  next=""
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
    [ -n "$next" ] && [ "$next" != "done" ] && [ "$(find "$state" -mtime +7 2>/dev/null)" ] && STALE=$((STALE + 1))
  fi
  artifact_count=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$state" ] && [ "$artifact_count" -eq 0 ]; then
    GAPS=$((GAPS + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"
[ "$GAPS" -gt 0 ] && echo "- 产物缺口任务数: ${GAPS}"
[ "$STALE" -gt 0 ] && echo "- 停滞 7+ 天任务数: ${STALE}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    stage="unknown"
    next="unknown"
    deliverable="-"
    updated="-"
    artifacts=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      deliverable=$(grep "^deliverable:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/risks/*.md >/dev/null 2>&1 && artifacts="${artifacts}RISK "
    ls "$dir"/stakeholders/*.md >/dev/null 2>&1 && artifacts="${artifacts}STAKE "
    ls "$dir"/timeline/*.md >/dev/null 2>&1 && artifacts="${artifacts}TIME "
    [ -z "$artifacts" ] && artifacts="INIT"

    echo "  - ${name} | workflow=${workflow:-unknown} | stage=${stage:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | deliverable=${deliverable:--} | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /senior-project-manager:spm 装配任务；如需恢复，可直接说明“继续上次项目管理任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/spm/references/senior-project-manager-agent.md"
