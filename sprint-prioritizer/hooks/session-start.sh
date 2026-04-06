#!/bin/bash
# SessionStart hook for sprint-prioritizer plugin
# 1. 创建顶层工作目录
# 2. 输出 Sprint Prioritizer Agent 提示词到 stdout（注入为会话上下文）

# 创建 _sprint 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _sprint

# 输出 Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/sp/references/sprint-prioritizer-agent.md"
