#!/bin/bash
# SessionStart hook for product-manager plugin
# 1. 创建工作目录结构
# 2. 输出 PO Agent 提示词到 stdout（注入为会话上下文）

# 创建 _requirements 目录结构（如果不存在）
mkdir -p _requirements/raw _requirements/domain _requirements/prd

# 输出 PO Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/pa/references/po-agent.md"
