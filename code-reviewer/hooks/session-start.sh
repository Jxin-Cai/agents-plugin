#!/bin/bash
# SessionStart hook for code-reviewer plugin
# 1. 初始化工作目录
# 2. 展示工作区状态（历史审查、活跃任务、可恢复任务）
# 3. 注入角色行为原则

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}"
WORKSPACE="_code-review"

mkdir -p "$WORKSPACE"

echo "## Code Reviewer 工作台"
echo ""

TOTAL=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
ACTIVE=0

if [ "$TOTAL" -gt 0 ]; then
  echo "### 历史审查（${TOTAL} 个）"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/review-state.md"
    workflow="-"
    next="done"
    blockers="-"

    if [ -f "$state" ]; then
      workflow=$(grep "^- workflow:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      blockers=$(grep -i "blocker" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      [ -n "$next" ] && [ "$next" != "done" ] && ACTIVE=$((ACTIVE + 1))
    fi

    artifacts=""
    ls "$dir"/security/security-report-*.md >/dev/null 2>&1 && artifacts="${artifacts}SEC "
    ls "$dir"/quality/quality-report-*.md >/dev/null 2>&1 && artifacts="${artifacts}QLT "
    ls "$dir"/refactoring/refactor-report-*.md >/dev/null 2>&1 && artifacts="${artifacts}REF "
    [ -z "$artifacts" ] && artifacts="INIT"

    echo "- ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | artifacts=[${artifacts}] | blockers=${blockers:--}"
  done < <(ls -dt "$WORKSPACE"/*/ 2>/dev/null | head -5)
  echo ""
  echo "- 活跃审查: ${ACTIVE} 个"
  echo ""
fi

echo "输入 \`/cr <目标>\` 开始代码审查；如需恢复，可直接说明“继续上次审查”。"
echo ""

cat "${PLUGIN_ROOT}/skills/cr/references/code-reviewer-agent.md"
