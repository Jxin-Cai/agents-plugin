#!/bin/bash
# SessionStart hook for software-architect plugin

WORKSPACE="_architecture"
STATE_NAME="arch-state.md"
mkdir -p "$WORKSPACE"

echo "## 架构工作台状态"
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
      target=$(grep "^business_goal:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/design/system-design-*.md >/dev/null 2>&1 && artifacts="${artifacts}DES "
    ls "$dir"/design/architecture-review-*.md >/dev/null 2>&1 && artifacts="${artifacts}REV "
    ls "$dir"/adr/adr-*.md >/dev/null 2>&1 && artifacts="${artifacts}ADR "
    [ -z "$artifacts" ] && artifacts="INIT"
    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | goal=${target:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

echo ""
echo "- 提示: 默认先走 /software-architect:sa 装配任务；如需恢复，可直接说明“继续上次架构任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/sa/references/software-architect-agent.md"
