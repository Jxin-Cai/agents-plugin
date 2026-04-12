#!/bin/bash
# SessionStart hook for ui-designer plugin
# 1. 创建顶层工作目录
# 2. 展示工作区状态（任务数、近期评审、断点检测）
# 3. 输出 UI Designer Agent 提示词到 stdout（注入为会话上下文）

WORKSPACE="_design-review"

# 创建 _design-review 顶层目录（具体评审子目录在流程中按日期创建）
mkdir -p "$WORKSPACE"

# ── 工作区状态 ──
echo "## UI 设计评审工作区"
echo ""

# 统计任务数
TASK_COUNT=$(find "$WORKSPACE" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 评审任务总数: ${TASK_COUNT}"

# 列出近期评审目录（最近 5 个）
if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 近期评审:"
  ls -1td "$WORKSPACE"/*/ 2>/dev/null | head -5 | while read -r dir; do
    dirname=$(basename "$dir")
    # 检查是否有状态文件
    if [ -f "$dir/meta/design-review-state.md" ]; then
      next_step=$(grep "^next_step:" "$dir/meta/design-review-state.md" 2>/dev/null | head -1 | sed 's/next_step: *//')
      echo "  - ${dirname} (进行中 → ${next_step:-未知})"
    else
      # 通过产物推断完成度
      has_visual=$(ls "$dir"/visual/visual-audit-*.md 2>/dev/null | head -1)
      has_ds=$(ls "$dir"/design-system/ds-review-*.md 2>/dev/null | head -1)
      has_proto=$(ls "$dir"/prototype/prototype-feedback-*.md 2>/dev/null | head -1)
      stages=""
      [ -n "$has_visual" ] && stages="${stages}VA "
      [ -n "$has_ds" ] && stages="${stages}DSR "
      [ -n "$has_proto" ] && stages="${stages}PF "
      if [ -n "$stages" ]; then
        echo "  - ${dirname} (已完成: ${stages})"
      else
        echo "  - ${dirname}"
      fi
    fi
  done
else
  echo "- 暂无评审任务，使用 /uid 开始"
fi

# 快扫产物计数
QUICK_SCAN_COUNT=$(ls "$WORKSPACE"/quick-scan-*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$QUICK_SCAN_COUNT" -gt 0 ]; then
  echo "- 快扫报告: ${QUICK_SCAN_COUNT} 份"
fi

echo ""

# 输出 UI Designer Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/uid/references/ui-designer-agent.md"
