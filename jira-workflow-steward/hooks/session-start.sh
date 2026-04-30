#!/bin/bash
# SessionStart hook for jira-workflow-steward plugin

WORKSPACE="_jira-workflow"
STATE_NAME="workflow-state.md"
mkdir -p "$WORKSPACE"

find_req_config() {
  local dir="$PWD"
  while [ "$dir" != "/" ]; do
    if [ -f "$dir/.requirement-mgmt/config.yaml" ]; then
      echo "$dir/.requirement-mgmt/config.yaml"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

echo "## Jira 工作流工作台状态"
echo ""

TASK_COUNT=$(find "$WORKSPACE" -maxdepth 1 -mindepth 1 -type d ! -name ".*" 2>/dev/null | wc -l | tr -d ' ')
RESUMABLE=0
GAPS=0

for dir in "$WORKSPACE"/*/; do
  [ -d "$dir" ] || continue
  state="$dir/meta/$STATE_NAME"
  next=""
  if [ -f "$state" ]; then
    next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    [ -n "$next" ] && [ "$next" != "done" ] && RESUMABLE=$((RESUMABLE + 1))
  fi
  artifact_count=$(find "$dir" -type f -name "*.md" ! -path "*/meta/*" ! -path "*/context/*" ! -path "*/.checkpoints/*" 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$state" ] && [ "$artifact_count" -eq 0 ]; then
    GAPS=$((GAPS + 1))
  fi
done

echo "- 任务数: ${TASK_COUNT}"
echo "- 可接续任务数: ${RESUMABLE}"
[ "$GAPS" -gt 0 ] && echo "- 产物缺口任务数: ${GAPS}"

if [ "$TASK_COUNT" -gt 0 ]; then
  echo "- 最近任务:"
  while IFS= read -r dir; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    state="$dir/meta/$STATE_NAME"
    workflow="-"
    stage="unknown"
    next="unknown"
    completed="[]"
    updated="-"
    artifacts=""

    if [ -f "$state" ]; then
      workflow=$(grep "^workflow_mode:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      stage=$(grep "^current_stage:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      completed=$(grep "^completed_stages:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
      updated=$(grep "^updated_at:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
    fi

    ls "$dir"/workflows/*.md >/dev/null 2>&1 && artifacts="${artifacts}WF "
    ls "$dir"/triage/*.md >/dev/null 2>&1 && artifacts="${artifacts}TR "
    ls "$dir"/boards/*.md >/dev/null 2>&1 && artifacts="${artifacts}BD "
    [ -z "$artifacts" ] && artifacts="INIT"

    echo "  - ${name} | workflow=${workflow:-unknown} | stage=${stage:-unknown} | next=${next:-unknown} | completed=${completed:-[]} | artifacts=[${artifacts}] | updated=${updated:--}"
  done < <(ls -1dt "$WORKSPACE"/*/ 2>/dev/null | head -3)
fi

if req_config=$(find_req_config); then
  echo "- 需求平台: ✅ 已连接 (${req_config})"
else
  echo "- 需求平台: ❌ 未配置（可直接用 /req 或 /req-setup，缺配置时会引导初始化）"
fi

echo ""
echo "- 提示: 默认先走 /jira-workflow-steward:jws 装配任务；如需恢复，可直接说明“继续上次 Jira 任务”。"
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/jws/references/jira-workflow-steward-agent.md"
