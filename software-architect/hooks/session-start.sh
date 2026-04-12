#!/bin/bash
# SessionStart hook for software-architect plugin

mkdir -p _architecture

# 工作区状态感知
echo "## 架构工作台状态"
echo ""

# 统计已有架构任务
task_count=$(find _architecture -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 架构任务数: ${task_count}"

# 显示最近任务
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _architecture/ 2>/dev/null | head -3 | while read d; do
    state_file="_architecture/${d}/meta/arch-state.md"
    if [ -f "$state_file" ]; then
      mode=$(grep "^workflow_mode:" "$state_file" 2>/dev/null | cut -d' ' -f2)
      next=$(grep "^next_step:" "$state_file" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} [${mode:-unknown}] → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done
fi

echo ""

# 注入角色行为原则
cat "${CLAUDE_PLUGIN_ROOT}/skills/sa/references/software-architect-agent.md"
