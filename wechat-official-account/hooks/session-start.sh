#!/bin/bash
# SessionStart hook for wechat-official-account plugin
# 1. 创建顶层工作目录
# 2. 输出微信公众号运营 Agent 提示词到 stdout（注入为会话上下文）

# 创建 _wechat-oa 顶层目录（具体任务子目录在流程中按日期创建）
mkdir -p _wechat-oa

# 输出微信公众号运营 Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/woa/references/wechat-oa-agent.md"
