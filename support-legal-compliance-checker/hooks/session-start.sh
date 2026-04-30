#!/bin/bash
# SessionStart hook for support-legal-compliance-checker plugin

WORKSPACE="_legal-compliance"
STATE_NAME="state.md"
mkdir -p "$WORKSPACE/shared"

echo "## 法律合规检查工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" ! -name "shared" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0
COUNSEL_REVIEW=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  [ "$(basename "$dir")" = "shared" ] && continue
  state="$dir/meta/$STATE_NAME"
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
    if grep -q "^counsel_review_needed: true" "$state" 2>/dev/null; then
      COUNSEL_REVIEW=$((COUNSEL_REVIEW + 1))
    fi
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"
echo "- 待法律顾问确认任务数: ${COUNSEL_REVIEW}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    [ "$(basename "$dir")" = "shared" ] && continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    stage="unknown"
    next="unknown"
    updated="-"
    artifact="-"

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    artifact=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/shared/*" 2>/dev/null | xargs ls -1t 2>/dev/null | head -1 | xargs -n1 basename 2>/dev/null)
    [ -z "$artifact" ] && artifact="-"
    echo "  - ${name} | workflow=${workflow:-unknown} | stage=${stage:-unknown} | artifact=${artifact} | next=${next:-unknown} | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -4)
fi

echo "- 共享资产:"
audits=$(find "$WORKSPACE" -path "*/audits/*" -type f 2>/dev/null | wc -l | tr -d ' ')
policies=$(find "$WORKSPACE" -path "*/policies/*" -type f 2>/dev/null | wc -l | tr -d ' ')
contracts=$(find "$WORKSPACE" -path "*/contracts/*" -type f 2>/dev/null | wc -l | tr -d ' ')
echo "  - 审计资产数: ${audits}"
echo "  - 政策资产数: ${policies}"
echo "  - 合同资产数: ${contracts}"

echo ""
echo "- 提示: 默认先走 /support-legal-compliance-checker:slc 装配任务；如需恢复，可直接说明“继续上次合规任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/slc/references/legal-compliance-agent.md"
