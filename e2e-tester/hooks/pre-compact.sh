#!/bin/bash
# PreCompact hook: 上下文压缩前保存关键任务状态到检查点
# 防止长测试会话因 context 压缩导致进度丢失

CHECKPOINT_DIR=".e2e-tests/shared/.checkpoints"
mkdir -p "$CHECKPOINT_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CHECKPOINT_FILE="${CHECKPOINT_DIR}/pre-compact-${TIMESTAMP}.md"

{
  echo "# Pre-Compact Checkpoint"
  echo ""
  echo "> 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')，用于上下文压缩后恢复任务状态。"
  echo ""

  # 记录活跃 run 状态
  echo "## 活跃任务"
  echo ""
  for INDEX_FILE in $(find .e2e-tests/scenarios -path "*/runs/*/index.md" 2>/dev/null | sort -r | head -5); do
    SCENARIO=$(echo "$INDEX_FILE" | sed 's|.e2e-tests/scenarios/||;s|/runs/.*||')
    RUN=$(echo "$INDEX_FILE" | sed 's|.*/runs/||;s|/index.md||')
    # 提取 frontmatter 关键字段
    STATUS=$(sed -n 's/^status: *//p' "$INDEX_FILE" 2>/dev/null | head -1)
    STAGE=$(sed -n 's/^current_stage: *//p' "$INDEX_FILE" 2>/dev/null | head -1)
    WORKFLOW=$(sed -n 's/^workflow: *//p' "$INDEX_FILE" 2>/dev/null | head -1)
    echo "- **${SCENARIO}** / \`${RUN}\`"
    echo "  - status: ${STATUS:-unknown}, stage: ${STAGE:-unknown}, workflow: ${WORKFLOW:-unknown}"
    echo "  - index: ${INDEX_FILE}"
  done

  # 记录最近操作的文件
  echo ""
  echo "## 最近修改的测试文件（5 分钟内）"
  echo ""
  find .e2e-tests -name "*.md" -newer /tmp/.e2e-compact-marker -mmin -5 2>/dev/null | head -10 | while read -r f; do
    echo "- $f"
  done

  # 记录 knowledge-index 摘要
  if [ -f ".e2e-tests/shared/knowledge-index.md" ]; then
    echo ""
    echo "## Knowledge Index 摘要"
    echo ""
    # 提取各表的行数
    for TABLE in "环境配置" "自动化脚本" "认证脚本" "活跃剧本" "已知陷阱"; do
      COUNT=$(sed -n "/^## ${TABLE}/,/^## /{/^|[^-|]/p}" .e2e-tests/shared/knowledge-index.md 2>/dev/null | grep -v "^| " | head -1 | wc -l | tr -d ' ')
      echo "- ${TABLE}: 约 ${COUNT} 条"
    done
  fi

} > "$CHECKPOINT_FILE"

# 保留最近 5 个检查点，清理旧的
ls -t "${CHECKPOINT_DIR}"/pre-compact-*.md 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

echo "💾 已保存 pre-compact 检查点: ${CHECKPOINT_FILE}"
