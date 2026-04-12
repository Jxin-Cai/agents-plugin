#!/bin/bash
# SessionStart hook for backend-architect plugin
# 1. 创建顶层工作目录
# 2. 检测并展示已有架构任务（含任务计数与进度）
# 3. 注入 Agent 角色宪章

# 创建工作目录
mkdir -p _backend-arch

# 展示已有架构任务
if [ -d "_backend-arch" ] && [ "$(ls -A _backend-arch 2>/dev/null)" ]; then
  TASK_COUNT=$(ls -d _backend-arch/*/ 2>/dev/null | wc -l | tr -d ' ')
  echo "## 架构工作区状态（共 ${TASK_COUNT} 个任务）"
  echo ""
  for dir in _backend-arch/*/; do
    [ -d "$dir" ] || continue
    slug=$(basename "$dir")
    DONE=""
    ls "$dir"api/api-design-*.md 1>/dev/null 2>&1 && DONE="${DONE}API "
    ls "$dir"database/db-model-*.md 1>/dev/null 2>&1 && DONE="${DONE}DB "
    ls "$dir"scalability/scalability-review-*.md 1>/dev/null 2>&1 && DONE="${DONE}Scale "
    ls "$dir"microservice/microservice-design-*.md 1>/dev/null 2>&1 && DONE="${DONE}MS "
    ls "$dir"tech-debt/tech-debt-assessment-*.md 1>/dev/null 2>&1 && DONE="${DONE}TD "
    if [ -n "$DONE" ]; then
      echo "- ${slug} [${DONE}]"
    else
      echo "- ${slug} (初始化)"
    fi
  done
  echo ""
fi

# 注入 Agent 角色宪章
cat "${CLAUDE_PLUGIN_ROOT}/skills/bea/references/backend-architect-agent.md"
