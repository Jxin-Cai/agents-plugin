#!/bin/bash
# SessionStart hook for e2e-tester plugin
# 1. 创建顶层工作目录（shared/ 公共区 + scenarios/ 剧本区）
# 2. 展示 QA 工作台状态

# ── 公共可复用资源区 ──
mkdir -p .e2e-tests/shared/env
mkdir -p .e2e-tests/shared/automation/auth
mkdir -p .e2e-tests/shared/datasets
mkdir -p .e2e-tests/shared/mocks
mkdir -p .e2e-tests/shared/helpers
mkdir -p .e2e-tests/shared/registry
mkdir -p .e2e-tests/shared/reports

# ── 测试剧本区 ──
mkdir -p .e2e-tests/scenarios

# 展示 QA 工作台状态
if [ -d ".e2e-tests" ]; then
  echo "---"
  echo "## QA 工作台状态"
  echo ""

  SCENARIO_COUNT=$(find .e2e-tests/scenarios -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  echo "- 测试剧本: ${SCENARIO_COUNT} 个"

  ACTIVE_RUNS=$(find .e2e-tests/scenarios -path "*/runs/*/index.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "- 可接续执行: ${ACTIVE_RUNS} 个"

  if [ -f ".e2e-tests/shared/quality-ledger.md" ]; then
    echo "- quality-ledger: 已存在"
  else
    echo "- quality-ledger: 未初始化"
  fi

  if [ -f ".e2e-tests/shared/registry/index.yaml" ]; then
    echo "- registry: 已存在"
  else
    echo "- registry: 未初始化"
  fi

  ENV_COUNT=$(ls .e2e-tests/shared/env/*.yaml 2>/dev/null | wc -l | tr -d ' ')
  echo "- 环境配置: ${ENV_COUNT} 个"

  SCRIPT_COUNT=$(find .e2e-tests/shared/automation -name "*.ts" 2>/dev/null | wc -l | tr -d ' ')
  echo "- 沉淀脚本: ${SCRIPT_COUNT} 个"

  AUTH_COUNT=$(find .e2e-tests/shared/automation/auth -name "*.ts" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$AUTH_COUNT" -gt 0 ]; then
    echo "- 认证脚本: ${AUTH_COUNT} 个"
  fi

  if [ -d ".e2e-tests/shared/reports" ] && [ "$(ls -A .e2e-tests/shared/reports 2>/dev/null)" ]; then
    LATEST_REPORT=$(ls -t .e2e-tests/shared/reports 2>/dev/null | head -n 1)
    echo "- 最近回归报告: ${LATEST_REPORT}"
  fi

  echo ""
  echo "支持的 QA 工作场景：新功能验收 / 发布验证 / 回归 / 影响分析 / 缺陷复现 / 专项验证 / 脚本维护"
  echo "---"
  echo ""
fi
