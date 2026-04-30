#!/bin/bash
# SessionStart hook for wechat-official-account plugin

WORKSPACE="_wechat-oa"
STATE_NAME="state.md"
SHARED_DIR="$WORKSPACE/shared"
mkdir -p "$WORKSPACE" "$SHARED_DIR"

find_extend_config() {
  if [ -f "$PWD/EXTEND.md" ]; then
    echo "$PWD/EXTEND.md"
    return 0
  fi
  if [ -f "$HOME/.wechat-oa/EXTEND.md" ]; then
    echo "$HOME/.wechat-oa/EXTEND.md"
    return 0
  fi
  return 1
}

echo "## 微信公众号运营工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" ! -name "shared" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  [ "$(basename "$dir")" = "shared" ] && continue
  state="$dir/meta/$STATE_NAME"
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    [ "$(basename "$dir")" = "shared" ] && continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    next="unknown"
    updated="-"

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    echo "  - ${name} | workflow=${workflow:-unknown} | next=${next:-unknown} | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -4)
fi

echo "- 共享资产:"
latest_strategy=$(find "$WORKSPACE" -path "*/strategy/*.md" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
latest_article=$(find "$WORKSPACE" -path "*/articles/article-*.md" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
latest_publish=$(find "$WORKSPACE" -path "*/articles/publish-report-*.md" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
latest_analytics=$(find "$WORKSPACE" -path "*/analytics/*.md" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
[ -z "$latest_strategy" ] && latest_strategy="-"
[ -z "$latest_article" ] && latest_article="-"
[ -z "$latest_publish" ] && latest_publish="-"
[ -z "$latest_analytics" ] && latest_analytics="-"
echo "  - 最近策略: ${latest_strategy}"
echo "  - 最近文章: ${latest_article}"
echo "  - 最近发布报告: ${latest_publish}"
echo "  - 最近分析报告: ${latest_analytics}"

if extend_cfg=$(find_extend_config); then
  echo "  - EXTEND 配置: ✅ 已就绪 (${extend_cfg})"
else
  echo "  - EXTEND 配置: ❌ 未找到（可在项目根目录或 ~/.wechat-oa/EXTEND.md 配置）"
fi

echo ""
echo "- 提示: 默认先走 /wechat-official-account:woa 装配任务；如需恢复，可直接说明“继续上次公众号任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/woa/references/wechat-oa-agent.md"
