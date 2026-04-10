#!/usr/bin/env bash
set -euo pipefail

# 创建分析工作目录
mkdir -p _analytics

# 输出 agent 参考文档供上下文加载
cat "$(dirname "$0")/../skills/sar/references/analytics-reporter-agent.md"
