#!/bin/bash
# Stop hook: 每轮结束后轻量检查项目管理状态一致性

WORKSPACE="_project-mgmt"
STATE_NAME="state.md"
[ -d "$WORKSPACE" ] || exit 0

ISSUES=""

for state in "$WORKSPACE"/*/meta/$STATE_NAME; do
  [ -f "$state" ] || continue
  dir=$(dirname "$(dirname "$state")")
  name=$(basename "$dir")
  next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  artifacts=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$next" = "done" ] && [ "$artifacts" -eq 0 ]; then
    ISSUES="${ISSUES}
- ${name}: 状态已完成但未发现阶段产物"
  fi

  if [ -n "$next" ] && [ "$next" != "done" ] && [ "$(find "$state" -mtime +7 2>/dev/null)" ]; then
    ISSUES="${ISSUES}
- ${name}: next_step=${next}，但状态文件已 7+ 天未更新"
  fi

  for summary in "$dir"/meta/*-summary.md; do
    [ -f "$summary" ] || continue
    lines=$(wc -l < "$summary" | tr -d ' ')
    if [ "$lines" -gt 20 ]; then
      ISSUES="${ISSUES}
- ${name}: $(basename "$summary") 超过 20 行，建议压缩摘要"
    fi
  done
done

if [ -n "$ISSUES" ]; then
  echo ""
  echo "### 高级项目经理工作台状态检查"
  echo -e "$ISSUES"
  echo ""
fi
