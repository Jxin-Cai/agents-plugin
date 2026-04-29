#!/bin/bash
# Stop hook: 每轮结束后轻量检查状态一致性
# 仅在 .e2e-tests 目录存在时运行，输出简洁

[ -d ".e2e-tests" ] || exit 0

ISSUES=""

# 检查 1: registry index.yaml 存在但域文件缺失
if [ -f ".e2e-tests/shared/registry/index.yaml" ]; then
  # 简单检查：index 引用的域文件是否存在
  for DOMAIN_FILE in $(grep -oP '\w+\.yaml' .e2e-tests/shared/registry/index.yaml 2>/dev/null | sort -u); do
    if [ "$DOMAIN_FILE" != "index.yaml" ] && [ ! -f ".e2e-tests/shared/registry/$DOMAIN_FILE" ]; then
      ISSUES="${ISSUES}\n⚠️ registry 引用了 ${DOMAIN_FILE} 但文件不存在"
    fi
  done
fi

# 检查 2: 活跃 run 的 index.md status=active 但超过 7 天未更新
for INDEX_FILE in $(find .e2e-tests/scenarios -path "*/runs/*/index.md" 2>/dev/null); do
  STATUS=$(sed -n 's/^status: *//p' "$INDEX_FILE" 2>/dev/null | head -1)
  if [ "$STATUS" = "active" ]; then
    # 检查文件修改时间是否超过 7 天
    if [ "$(find "$INDEX_FILE" -mtime +7 2>/dev/null)" ]; then
      RUN_PATH=$(echo "$INDEX_FILE" | sed 's|/index.md||')
      ISSUES="${ISSUES}\n⚠️ 任务 ${RUN_PATH} 状态为 active 但已 7+ 天未更新"
    fi
  fi
done

# 检查 3: knowledge-index.md 超过容量阈值
if [ -f ".e2e-tests/shared/knowledge-index.md" ]; then
  LINES=$(wc -l < .e2e-tests/shared/knowledge-index.md | tr -d ' ')
  if [ "$LINES" -gt 200 ]; then
    ISSUES="${ISSUES}\n⚠️ knowledge-index.md 超过 200 行 (${LINES} 行)，需要截断"
  fi
fi

# 只有发现问题时才输出
if [ -n "$ISSUES" ]; then
  echo ""
  echo "### QA 状态检查"
  echo -e "$ISSUES"
  echo ""
fi
