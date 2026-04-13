#!/bin/bash
# SessionStart hook for wechat-official-account plugin

mkdir -p _wechat-oa

echo "## 微信公众号运营工作台状态"
echo ""
task_count=$(find _wechat-oa -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
echo "- 任务数: ${task_count}"
if [ "$task_count" -gt 0 ]; then
  echo "- 最近任务:"
  ls -1t _wechat-oa/ 2>/dev/null | while read d; do
    [ -d "_wechat-oa/$d" ] || continue
    state="_wechat-oa/${d}/meta/state.md"
    if [ -f "$state" ]; then
      next=$(grep "^next_step:" "$state" 2>/dev/null | cut -d' ' -f2)
      echo "  - ${d} → next: ${next:-done}"
    else
      echo "  - ${d}"
    fi
  done | head -3
fi
echo ""

cat "${CLAUDE_PLUGIN_ROOT}/skills/woa/references/wechat-oa-agent.md"
