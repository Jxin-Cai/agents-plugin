#!/bin/bash
# SessionStart hook for product-manager plugin
# 1. 创建顶层工作目录
# 2. 检测并展示知识库状态
# 3. 列出已有需求周期

# 创建工作目录
mkdir -p _requirements
mkdir -p _product_intelligence

# 知识库状态展示
if [ -f "_product_intelligence/product-context.md" ]; then
  echo "---"
  echo "## 产品知识库状态"
  echo ""
  # 统计决策记录数
  if [ -f "_product_intelligence/decision-journal.md" ]; then
    DECISIONS=$(grep -c "^## D" _product_intelligence/decision-journal.md 2>/dev/null || echo 0)
    echo "- 决策记录: ${DECISIONS} 条"
  fi
  # 统计领域术语数
  if [ -f "_product_intelligence/domain-glossary.md" ]; then
    TERMS=$(grep -c "^|" _product_intelligence/domain-glossary.md 2>/dev/null || echo 0)
    # 减去表头行
    TERMS=$((TERMS > 2 ? TERMS - 2 : 0))
    echo "- 领域术语: ${TERMS} 个"
  fi
  # 统计需求模式数
  if [ -f "_product_intelligence/patterns.md" ]; then
    PATTERNS=$(grep -c "^## PT" _product_intelligence/patterns.md 2>/dev/null || echo 0)
    echo "- 需求模式: ${PATTERNS} 个"
  fi
  # 最后更新时间
  if [ "$(uname)" = "Darwin" ]; then
    LAST=$(stat -f "%Sm" -t "%Y-%m-%d" _product_intelligence/product-context.md 2>/dev/null || echo "未知")
  else
    LAST=$(stat -c "%y" _product_intelligence/product-context.md 2>/dev/null | cut -d' ' -f1 || echo "未知")
  fi
  echo "- 最后更新: ${LAST}"
  echo "---"
  echo ""
else
  echo "---"
  echo "## 产品知识库"
  echo ""
  echo "知识库尚未初始化。运行 \`/product-manager:product-knowledge\` 进行初始化。"
  echo "---"
  echo ""
fi

# 列出已有需求周期
if [ -d "_requirements" ] && [ "$(ls -A _requirements 2>/dev/null)" ]; then
  echo "## 已有需求周期"
  echo ""
  ls -d _requirements/*/ 2>/dev/null | while read dir; do
    slug=$(basename "$dir")
    # 检查 PRD 是否存在
    if ls "$dir"/prd/prd-*.md 1>/dev/null 2>&1; then
      echo "- ${slug} ✅ (PRD 已生成)"
    else
      echo "- ${slug} ⏳ (进行中)"
    fi
  done
  echo ""
fi

