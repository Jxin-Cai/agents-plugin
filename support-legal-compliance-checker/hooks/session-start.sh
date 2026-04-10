#!/usr/bin/env bash
set -euo pipefail

# --- 初始化法律合规工作目录 ---
mkdir -p _legal-compliance

# --- 输出 Agent 工作台提示词 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cat "$SCRIPT_DIR/../skills/slc/references/legal-compliance-agent.md"
