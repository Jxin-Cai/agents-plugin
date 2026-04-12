#!/bin/bash
# SessionStart hook for frontend-developer plugin
# 1. 创建顶层工作目录
# 2. 展示工作区状态
# 3. 输出 Agent 提示词到 stdout（注入为会话上下文）

WORKSPACE="_frontend-review"

# 创建 _frontend-review 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p "$WORKSPACE"

# 展示工作区状态
echo ""
echo "## 前端审查工作区状态"
echo ""

# 统计任务数
TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 历史任务: ${TASK_COUNT} 个"

# 最近 3 个任务
if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null \
    | xargs -0 ls -dt 2>/dev/null \
    | head -3 \
    | while read -r dir; do
        DIRNAME=$(basename "$dir")
        # 检查是否有 state 文件
        if [ -f "$dir/meta/review-state.md" ]; then
          NEXT=$(grep "^next_step:" "$dir/meta/review-state.md" 2>/dev/null | head -1 | sed 's/next_step: *//')
          echo "  - \`${DIRNAME}\` (进度: ${NEXT:-已完成})"
        else
          # 统计产物文件数
          ARTIFACT_COUNT=$(find "$dir" -name "*.md" -not -path "*/meta/*" -not -path "*/context/*" 2>/dev/null | wc -l | tr -d ' ')
          echo "  - \`${DIRNAME}\` (产物: ${ARTIFACT_COUNT} 个)"
        fi
      done
fi

# 检查是否有未完成的任务（有 state 文件且 next_step 非空）
PENDING=""
for STATE_FILE in "$WORKSPACE"/*/meta/review-state.md; do
  [ -f "$STATE_FILE" ] || continue
  NEXT=$(grep "^next_step:" "$STATE_FILE" 2>/dev/null | head -1 | sed 's/next_step: *//')
  if [ -n "$NEXT" ] && [ "$NEXT" != "done" ]; then
    TASK_DIR=$(dirname "$(dirname "$STATE_FILE")")
    PENDING="$(basename "$TASK_DIR") → ${NEXT}"
    break
  fi
done

if [ -n "$PENDING" ]; then
  echo ""
  echo "**可接续任务**: \`${PENDING}\`"
fi

echo ""

# 输出前端开发专家 Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/fed/references/frontend-developer-agent.md"
