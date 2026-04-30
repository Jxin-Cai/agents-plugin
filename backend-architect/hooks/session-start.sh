#!/bin/bash
# SessionStart hook for backend-architect plugin
# 1. 创建顶层工作目录
# 2. 检测并展示已有架构任务（含 workflow / 推荐下一步 / 产物状态）
# 3. 注入 Agent 角色宪章

WORKSPACE="_backend-arch"
mkdir -p "$WORKSPACE"

if [ -d "$WORKSPACE" ] && [ "$(ls -A "$WORKSPACE" 2>/dev/null)" ]; then
  TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  echo "## 架构工作区状态（共 ${TASK_COUNT} 个任务）"
  echo ""

  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    slug=$(basename "$dir")
    state="$dir/meta/arch-state.md"
    workflow="-"
    next="初始化"
    goal="-"
    done_tags=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      goal=$(grep "^goal:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/api/api-design-*.md >/dev/null 2>&1 && done_tags="${done_tags}API "
    ls "$dir"/database/db-model-*.md >/dev/null 2>&1 && done_tags="${done_tags}DB "
    ls "$dir"/scalability/scalability-review-*.md >/dev/null 2>&1 && done_tags="${done_tags}Scale "
    ls "$dir"/microservice/microservice-design-*.md >/dev/null 2>&1 && done_tags="${done_tags}MS "
    ls "$dir"/tech-debt/tech-debt-assessment-*.md >/dev/null 2>&1 && done_tags="${done_tags}TD "
    [ -z "$done_tags" ] && done_tags="INIT"

    echo "- ${slug} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifacts=[${done_tags}] | goal=${goal:--}"
  done < <(ls -dt "$WORKSPACE"/*/ 2>/dev/null | head -5)
  echo ""
  echo "输入 \`/bea <任务>\` 开始新任务，或直接说明“继续上次架构任务”。"
  echo ""
fi

cat "${CLAUDE_PLUGIN_ROOT}/skills/bea/references/backend-architect-agent.md"
