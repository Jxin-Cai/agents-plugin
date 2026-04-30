#!/bin/bash
# Stop hook: 每轮结束后轻量检查后端架构任务状态一致性

WORKSPACE="_backend-arch"
STATE_NAME="arch-state.md"
[ -d "$WORKSPACE" ] || exit 0

ISSUES=""

for state in "$WORKSPACE"/*/meta/$STATE_NAME; do
  [ -f "$state" ] || continue
  dir=$(dirname "$(dirname "$state")")
  name=$(basename "$dir")
  next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  artifacts=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$next" = "done" ] && [ "$artifacts" -eq 0 ]; then
    ISSUES="${ISSUES}
- ${name}: 状态已完成但未发现阶段产物"
  fi

  if ! grep -q "^goal:" "$state" 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 缺少 goal 字段"
  fi

  if ! grep -q "^constraints:" "$state" 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 缺少 constraints 字段"
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
  echo "### 后端架构工作台状态检查"
  echo -e "$ISSUES"
  echo ""
fi
