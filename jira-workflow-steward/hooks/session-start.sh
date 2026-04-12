#!/bin/bash
# SessionStart hook for jira-workflow-steward plugin

mkdir -p _jira-workflow

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

if [ -f ".requirement-mgmt/config.yaml" ]; then
  echo "- 需求平台: ✅ 已连接"
else
  echo "- 需求平台: ❌ 未配置（可用 /req-setup 配置）"
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/jws/references/jira-workflow-steward-agent.md"
