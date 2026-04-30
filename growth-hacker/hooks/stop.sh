#!/bin/bash
# Stop hook: 每轮结束后轻量检查增长任务状态一致性

WORKSPACE="_growth-hacking"
STATE_NAME="state.md"
[ -d "$WORKSPACE" ] || exit 0

ISSUES=""

for state in "$WORKSPACE"/*/meta/$STATE_NAME; do
  [ -f "$state" ] || continue
  dir=$(dirname "$(dirname "$state")")
  name=$(basename "$dir")
  next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  metric=$(grep "^north_star_metric:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  artifacts=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$next" = "done" ] && [ "$artifacts" -eq 0 ]; then
    ISSUES="${ISSUES}
- ${name}: 状态已完成但未发现阶段产物"
  fi

  if [ -z "$metric" ]; then
    ISSUES="${ISSUES}
- ${name}: 缺少 north_star_metric，增长判断依据不完整"
  fi

  if [ "$stage" = "growth-experiment" ] && ! grep -Eq "sample|样本量" "$dir"/experiments/*.md 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 实验阶段未发现最小样本量证据"
  fi

  if [ "$stage" = "viral-loop-design" ] && ! grep -Eq "K-factor|K 值|病毒系数" "$dir"/viral/*.md 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 病毒阶段未发现 K-factor 证据"
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
  echo "### 增长黑客工作台状态检查"
  echo -e "$ISSUES"
  echo ""
fi
