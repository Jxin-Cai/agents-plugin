#!/usr/bin/env bash
set -euo pipefail

# dispatcher.sh — 需求管理操作的统一入口
# 用法: dispatcher.sh <operation> [args...]
# 操作: setup, fetch, comment, transitions, transition, attach, search, create, update
#
# 读取 .requirement-mgmt/config.yaml 中的 provider 配置，
# 将操作路由到对应 provider 的 api.sh。

# 解析自身真实路径（穿透 symlink），定位到 _lib/
LIB_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$0")")" && pwd)"
SKILLS_ROOT="$(cd "$LIB_DIR/.." && pwd)"
PROVIDERS_DIR="$SKILLS_ROOT/_providers"

source "$LIB_DIR/config-reader.sh"

ACTION="${1:-}"
shift || true

if [[ -z "$ACTION" ]]; then
    echo "Usage: dispatcher.sh <operation> [args...]" >&2
    echo "Operations: setup, fetch, comment, transitions, transition, attach, search, create, update" >&2
    exit 1
fi

# setup 不需要已有配置
if [[ "$ACTION" == "setup" ]]; then
    echo "REQMGMT_SETUP_MODE=true"
    echo "PROVIDERS_DIR=$PROVIDERS_DIR"
    list_providers "$PROVIDERS_DIR"
    exit 0
fi

# 其他操作需要配置
CONFIG_PATH=$(find_config) || {
    echo "ERROR: 未找到 .requirement-mgmt/config.yaml" >&2
    echo "请先执行 /req-setup 完成配置，或手动准备 .requirement-mgmt/config.yaml。" >&2
    exit 1
}

PROVIDER=$(read_config_field "$CONFIG_PATH" "provider")

if [[ -z "$PROVIDER" ]]; then
    echo "ERROR: config.yaml 中未指定 provider" >&2
    exit 1
fi

PROVIDER_SCRIPT="$PROVIDERS_DIR/$PROVIDER/api.sh"
if [[ ! -f "$PROVIDER_SCRIPT" ]]; then
    echo "ERROR: Provider '$PROVIDER' 未找到: $PROVIDER_SCRIPT" >&2
    echo "可用 providers:" >&2
    list_providers "$PROVIDERS_DIR" | while IFS='|' read -r name display; do
        echo "  - $name ($display)" >&2
    done
    exit 1
fi

# 导出配置为环境变量供 provider 使用
export REQMGMT_CONFIG_PATH="$CONFIG_PATH"
export REQMGMT_PROVIDER="$PROVIDER"
export REQMGMT_PROJECT_ROOT="$(cd "$(dirname "$CONFIG_PATH")/.." && pwd)"
eval "$(load_provider_env "$CONFIG_PATH")"

# 委派给 provider
exec bash "$PROVIDER_SCRIPT" "$ACTION" "$@"
