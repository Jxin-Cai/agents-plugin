#!/bin/bash
# Stop hook: 每轮结束后轻量检查合规任务状态一致性

WORKSPACE="_legal-compliance"
STATE_NAME="state.md"
[ -d "$WORKSPACE" ] || exit 0

ISSUES=""

for state in "$WORKSPACE"/*/meta/$STATE_NAME; do
  [ -f "$state" ] || continue
  dir=$(dirname "$(dirname "$state")")
  [ "$(basename "$dir")" = "shared" ] && continue
  name=$(basename "$dir")
  next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  artifacts=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/shared/*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$next" = "done" ] && [ "$artifacts" -eq 0 ]; then
    ISSUES="${ISSUES}
- ${name}: 状态已完成但未发现阶段产物"
  fi

  if ! grep -q "^jurisdiction_scope:" "$state" 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 缺少 jurisdiction_scope 字段"
  fi

  if ! grep -q "^regulation_scope:" "$state" 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 缺少 regulation_scope 字段"
  fi

  if find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/shared/*" 2>/dev/null | grep -q .; then
    if ! grep -R -E "不构成正式法律意见|仅供参考" "$dir"/audits "$dir"/policies "$dir"/contracts >/dev/null 2>&1; then
      ISSUES="${ISSUES}
- ${name}: 产物中未发现免责声明证据"
    fi
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
  echo "### 法律合规检查工作台状态检查"
  echo -e "$ISSUES"
  echo ""
fi
