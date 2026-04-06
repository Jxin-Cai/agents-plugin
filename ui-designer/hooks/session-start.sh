#!/bin/bash
# SessionStart hook for ui-designer plugin
# 1. 创建顶层工作目录
# 2. 输出 UI Designer Agent 提示词到 stdout（注入为会话上下文）

# 创建 _design-review 顶层目录（具体评审子目录在流程中按日期创建）
mkdir -p _design-review

# 输出 UI Designer Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/uid/references/ui-designer-agent.md"
