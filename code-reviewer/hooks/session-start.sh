#!/bin/bash
# SessionStart hook for code-reviewer plugin
# 1. 初始化工作目录
# 2. 展示工作区状态（历史审查、活跃任务）
# 3. 注入角色行为原则

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
WORKSPACE="_code-review"

# 1. 初始化工作目录
mkdir -p "$WORKSPACE"

# 2. 工作区状态展示
echo "## Code Reviewer 工作台"
echo ""

# 统计历史审查目录
TOTAL=$(ls -d ${WORKSPACE}/*/ 2>/dev/null | wc -l | tr -d ' ')
if [ "$TOTAL" -gt 0 ]; then
  echo "### 历史审查 (${TOTAL} 个)"
  for dir in $(ls -dt ${WORKSPACE}/*/ 2>/dev/null | head -5); do
    name=$(basename "$dir")
    if [ -f "${dir}meta/review-state.md" ]; then
      echo "- ${name} [有状态记录]"
    else
      echo "- ${name}"
    fi
  done
  echo ""
fi

echo "输入 \`/cr <目标>\` 开始代码审查"
echo ""

# 3. 注入角色行为原则
cat "${PLUGIN_ROOT}/skills/cr/references/code-reviewer-agent.md"
