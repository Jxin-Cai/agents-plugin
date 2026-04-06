#!/bin/bash
# SessionStart hook for test-results-analyzer plugin
# 1. 创建顶层工作目录
# 2. 输出 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _test-analysis 顶层目录（具体分析子目录在流程中按日期创建）
mkdir -p _test-analysis

# 输出 Test Results Analyzer Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/tra/references/test-results-analyzer-agent.md"
