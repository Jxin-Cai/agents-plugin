#!/bin/bash
# SessionStart hook for product-manager plugin
# 1. 创建顶层工作目录
# 2. 输出 PO Agent 提示词到 stdout（注入为会话上下文）

# 创建 _requirements 顶层目录（具体需求子目录在流程中按日期创建）
mkdir -p _requirements

# 输出 PO Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/pa/references/po-agent.md"
