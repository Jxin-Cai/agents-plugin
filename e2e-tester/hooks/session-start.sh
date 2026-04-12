#!/bin/bash
# SessionStart hook for e2e-tester plugin
# 1. 创建顶层工作目录
# 2. 展示 QA 工作台状态

# 创建 .e2e-tests 顶层目录（具体领域子目录在流程中按需创建）
mkdir -p .e2e-tests
mkdir -p .e2e-tests/_shared
mkdir -p .e2e-tests/registry
mkdir -p .e2e-tests/reports

# 展示 QA 工作台状态
if [ -d ".e2e-tests" ]; then
  echo "---"
  echo "## QA 工作台状态"
  echo ""

  ACTIVE_TASKS=$(find .e2e-tests -path "*/task/index.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "- 可接续任务索引: ${ACTIVE_TASKS} 个"

  if [ -f ".e2e-tests/quality-ledger.md" ]; then
    echo "- quality-ledger: 已存在"
  else
    echo "- quality-ledger: 未初始化"
  fi

  if [ -f ".e2e-tests/registry/index.yaml" ]; then
    echo "- registry: 已存在"
  else
    echo "- registry: 未初始化"
  fi

  if [ -d ".e2e-tests/reports" ] && [ "$(ls -A .e2e-tests/reports 2>/dev/null)" ]; then
    LATEST_REPORT=$(ls -t .e2e-tests/reports 2>/dev/null | head -n 1)
    echo "- 最近报告目录: ${LATEST_REPORT}"
  fi

  echo ""
  echo "支持的 QA 工作场景：新功能验收 / 发布验证 / 回归 / 影响分析 / 缺陷复现 / 专项验证 / 脚本维护"
  echo "---"
  echo ""
fi
