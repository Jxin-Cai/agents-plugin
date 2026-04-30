#!/bin/bash
# Stop hook: 每轮结束后轻量检查基础设施任务状态一致性

WORKSPACE="_infrastructure"
STATE_NAME="workbench-state.md"
[ -d "$WORKSPACE" ] || exit 0

ISSUES=""

for state in "$WORKSPACE"/*/meta/$STATE_NAME; do
  [ -f "$state" ] || continue
  dir=$(dirname "$(dirname "$state")")
  name=$(basename "$dir")
  next=$(grep "^next_step:" "$state" 2>/dev/null | head -1 | cut -d':' -f2- | xargs)
  artifacts=$(find "$dir" -type f ! -path "*/meta/*" ! -path "*/context/*" 2>/dev/null | wc -l | tr -d ' ')

  if [ "$next" = "done" ] && [ "$artifacts" -eq 0 ]; then
    ISSUES="${ISSUES}
- ${name}: 状态已完成但未发现阶段产物"
  fi

  if ! grep -q "^slo_rto_rpo:" "$state" 2>/dev/null; then
    ISSUES="${ISSUES}
- ${name}: 缺少 SLO/RTO/RPO 目标字段"
  fi

  if grep -R "0.0.0.0/0" "$dir"/iac >/dev/null 2>&1; then
    ISSUES="${ISSUES}
- ${name}: 检测到过宽安全组 0.0.0.0/0"
  fi

  if ls "$dir"/backup/* >/dev/null 2>&1 && ! grep -R -E "gpg|openssl|kms|encrypt" "$dir"/backup >/dev/null 2>&1; then
    ISSUES="${ISSUES}
- ${name}: 备份目录未发现加密证据"
  fi
done

if [ -n "$ISSUES" ]; then
  echo ""
  echo "### 基础设施维护工作台状态检查"
  echo -e "$ISSUES"
  echo ""
fi
