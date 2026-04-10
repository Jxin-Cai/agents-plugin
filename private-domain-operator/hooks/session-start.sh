#!/bin/bash
# SessionStart hook for private-domain-operator plugin
# 1. 创建顶层工作目录
# 2. 输出私域运营 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _private-domain 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _private-domain

# 输出私域运营 Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/pdo/references/private-domain-operator-agent.md"
