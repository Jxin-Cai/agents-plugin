#!/bin/bash
# SessionStart hook for backend-architect plugin
# 1. 创建顶层工作目录
# 2. 检测并展示已有架构任务
# 3. 注入 Agent 角色宪章

# 创建工作目录
mkdir -p _backend-arch

# 展示已有架构任务
if [ -d "_backend-arch" ] && [ "$(ls -A _backend-arch 2>/dev/null)" ]; then
  echo "## 架构工作区状态"
  echo ""
  COUNT=0
  ls -d _backend-arch/*/ 2>/dev/null | while read dir; do
    slug=$(basename "$dir")
    DONE=""
    if ls "$dir"/api/api-design-*.md 1>/dev/null 2>&1; then
      DONE="${DONE}API "
    fi
    if ls "$dir"/database/db-model-*.md 1>/dev/null 2>&1; then
      DONE="${DONE}DB "
    fi
    if ls "$dir"/scalability/scalability-review-*.md 1>/dev/null 2>&1; then
      DONE="${DONE}Scale "
    fi
    if ls "$dir"/microservice/microservice-design-*.md 1>/dev/null 2>&1; then
      DONE="${DONE}MS "
    fi
    if ls "$dir"/tech-debt/tech-debt-assessment-*.md 1>/dev/null 2>&1; then
      DONE="${DONE}TD "
    fi
    if [ -n "$DONE" ]; then
      echo "- ${slug} [${DONE}]"
    else
      echo "- ${slug} (初始化)"
    fi
    COUNT=$((COUNT + 1))
  done
  echo ""
fi

# 注入 Agent 角色宪章
cat "${CLAUDE_PLUGIN_ROOT}/skills/bea/references/backend-architect-agent.md"
