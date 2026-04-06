#!/bin/bash
# SessionStart hook for code-reviewer plugin
# 1. 创建顶层工作目录
# 2. 输出 Code Reviewer Agent 提示词到 stdout（注入为会话上下文）

# 创建 _code-review 顶层目录（具体审查子目录在流程中按日期创建）
mkdir -p _code-review

# 输出 Code Reviewer Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/cr/references/code-reviewer-agent.md"
