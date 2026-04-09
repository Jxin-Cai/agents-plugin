#!/bin/bash
# SessionStart hook for e2e-tester plugin
# 1. 创建顶层工作目录
# 2. 输出 E2E Tester Agent 提示词到 stdout（注入为会话上下文）

# 创建 .e2e-tests 顶层目录（具体领域子目录在流程中按需创建）
mkdir -p .e2e-tests

# 输出 E2E Tester Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/e2e/references/e2e-agent.md"
