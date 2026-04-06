#!/bin/bash
# SessionStart hook for experiment-tracker plugin
# 1. 创建顶层工作目录
# 2. 输出 Experiment Tracker Agent 提示词到 stdout（注入为会话上下文）

# 创建 _experiments 顶层目录（具体实验子目录在流程中按日期创建）
mkdir -p _experiments

# 输出 Experiment Tracker Agent 提示词作为会话上下文
cat "${CLAUDE_PLUGIN_ROOT}/skills/et/references/experiment-tracker-agent.md"
