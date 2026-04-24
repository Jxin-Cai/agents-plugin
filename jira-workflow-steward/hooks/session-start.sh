#!/bin/bash
# SessionStart hook for jira-workflow-steward plugin

mkdir -p _jira-workflow

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
task_count=$(find _jira-workflow -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _jira-workflow/ 2>/dev/null | head -3 | while read d; do
    state="_jira-workflow/${d}/meta/workflow-state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi

if req_config=$(find_req_config); then
  echo "- 需求平台: ✅ 已连接 (${req_config})"
else
  echo "- 需求平台: ❌ 未配置（可直接用 /req 或 /req-setup，缺配置时会引导初始化）"
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/jws/references/jira-workflow-steward-agent.md"
