#!/bin/bash
# SessionStart hook for project-shepherd plugin
# 1. 创建顶层工作目录
# 2. 输出 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _project-health 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _project-health

# 输出 Project Shepherd Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/ps/references/project-shepherd-agent.md"
