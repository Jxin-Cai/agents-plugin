#!/bin/bash
# SessionStart hook for ai-citation-strategist plugin
# 1. 创建顶层工作目录
# 2. 输出 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _ai-citation 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _ai-citation

# 输出 AI Citation Strategist Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/acs/references/ai-citation-strategist-agent.md"
