#!/bin/bash
# SessionStart hook for frontend-developer plugin
# 1. 创建顶层工作目录
# 2. 输出 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _frontend-review 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _frontend-review

# 输出前端开发专家 Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/fed/references/frontend-developer-agent.md"
