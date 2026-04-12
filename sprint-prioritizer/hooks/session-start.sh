#!/bin/bash
# SessionStart hook for sprint-prioritizer plugin

mkdir -p _sprint

echo "## Sprint 优先级工作台状态"
echo ""
task_count=$(find _sprint -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- Sprint 任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _sprint/ 2>/dev/null | head -3 | while read d; do
    state="_sprint/${d}/meta/sprint-state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi

# 需求平台状态
if [ -f ".requirement-mgmt/config.yaml" ]; then
  echo "- 需求平台: ✅ 已连接"
else
  echo "- 需求平台: ❌ 未配置（可用 /req-setup 配置）"
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/sp/references/sprint-prioritizer-agent.md"
