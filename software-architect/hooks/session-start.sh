#!/bin/bash
# SessionStart hook for software-architect plugin
# 1. 创建顶层工作目录
# 2. 输出 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _architecture 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _architecture

# 输出 Software Architect Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/sa/references/software-architect-agent.md"
