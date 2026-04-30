#!/bin/bash
# Stop hook: 每轮结束后轻量检查公众号任务状态一致性

WORKSPACE="_wechat-oa"
STATE_NAME="state.md"
[ -d "$WORKSPACE" ] || exit 0

ISSUES=""

for state in "$WORKSPACE"/*/meta/$STATE_NAME; do
  [ -f "$state" ] || continue
  dir=$(dirname "$(dirname "$state")")
  [ "$(basename "$dir")" = "shared" ] && continue
  name=$(basename "$dir")
  next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  artifacts=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$next" = "done" ] && [ "$artifacts" -eq 0 ]; then
    ISSUES="${ISSUES}
- ${name}: 状态已完成但未发现阶段产物"
  fi

  if [ "$stage" = "publish-to-wechat" ] && ! ls "$dir"/articles/article-*.md >/dev/null 2>&1; then
    ISSUES="${ISSUES}
- ${name}: 待发布阶段缺少文章源稿"
  fi

  if [ "$next" = "subscriber-analytics" ] && ! ls "$dir"/articles/publish-report-*.md >/dev/null 2>&1; then
    ISSUES="${ISSUES}
- ${name}: 已进入分析阶段但未发现发布报告"
  fi

  data_window=$(grep "^data_window:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  if [ "$stage" = "subscriber-analytics" ] && [ -z "$data_window" -o "$data_window" = "unknown" ]; then
    ISSUES="${ISSUES}
- ${name}: 分析阶段缺少 data_window"
  fi
done

if [ -n "$ISSUES" ]; then
  echo ""
  echo "### 微信公众号运营工作台状态检查"
  echo -e "$ISSUES"
  echo ""
fi
