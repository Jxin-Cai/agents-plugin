#!/bin/bash
# SessionStart hook for senior-project-manager plugin
# 1. 创建顶层工作目录
# 2. 输出 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _project-mgmt 顶层目录（具体项目子目录在流程中按日期创建）
mkdir -p _project-mgmt

# 输出 Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/spm/references/senior-project-manager-agent.md"
