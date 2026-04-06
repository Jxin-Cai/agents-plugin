#!/bin/bash
# SessionStart hook for ux-researcher plugin
# 1. 创建顶层工作目录
# 2. 输出 UX Researcher Agent 提示词到 stdout（注入为会话上下文）

# 创建 _ux-research 顶层目录（具体研究子目录在流程中按日期创建）
mkdir -p _ux-research

# 输出 UX Researcher Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/uxr/references/ux-researcher-agent.md"
