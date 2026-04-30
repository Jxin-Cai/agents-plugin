#!/bin/bash
# PreCompact hook: 上下文压缩前保存关键代码审查任务状态到检查点

WORKSPACE="_code-review"
STATE_NAME="review-state.md"
CHECKPOINT_DIR="$WORKSPACE/.checkpoints"
mkdir -p "$CHECKPOINT_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CHECKPOINT_FILE="$CHECKPOINT_DIR/pre-compact-${TIMESTAMP}.md"

{
  echo "# Pre-Compact Checkpoint"
  echo ""
  echo "> 自动生成于 $(date '+%Y-%m-%d %H:%M:%S')，用于上下文压缩后恢复代码审查任务状态。"
  echo ""
  echo "## 最近任务"
  echo ""
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="unknown"
    status="unknown"
    next="unknown"
    artifact="INIT"

    if [ -f "$state" ]; then
      workflow=$(grep "^- workflow:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      status=$(grep "^- workflow_status:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/security/security-report-*.md >/dev/null 2>&1 && artifact="SEC"
    ls "$dir"/quality/quality-report-*.md >/dev/null 2>&1 && artifact="${artifact} QLT"
    ls "$dir"/refactoring/refactor-report-*.md >/dev/null 2>&1 && artifact="${artifact} REF"
    echo "- ${name} | workflow=${workflow:-unknown} | status=${status:-unknown} | next=${next:-unknown} | artifacts=[${artifact}]"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -5)
} > "$CHECKPOINT_FILE"

ls -1t "$CHECKPOINT_DIR"/pre-compact-*.md 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

echo "💾 已保存 pre-compact 检查点: $CHECKPOINT_FILE"
