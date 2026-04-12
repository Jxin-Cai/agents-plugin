#!/usr/bin/env bash
# config-reader.sh — YAML 配置解析库，由 dispatcher.sh source
# 依赖: python3 (用于解析 YAML)

# 从 config.yaml 读取指定字段（支持点号路径如 "connection.base_url"）
read_config_field() {
    local config_file="$1"
    local field="$2"
    python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
keys = sys.argv[2].split('.')
val = cfg
for k in keys:
    if isinstance(val, dict):
        val = val.get(k, '')
    else:
        val = ''
        break
    if not val:
        break
print(val if val else '')
" "$config_file" "$field"
}

# 将 config.yaml 中的 connection 和 options 字段导出为 REQMGMT_* 环境变量
# 输出可被 eval 执行的 export 语句
load_provider_env() {
    local config_file="$1"
    python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f) or {}
conn = cfg.get('connection', {}) or {}
opts = cfg.get('options', {}) or {}
for k, v in conn.items():
    if v is None:
        continue
    safe_v = str(v).replace('\\\\', '\\\\\\\\').replace('\"', '\\\\\"').replace('\n', '\\\\n')
    print(f'export REQMGMT_{k.upper()}=\"{safe_v}\"')
for k, v in opts.items():
    if v is None:
        continue
    safe_v = str(v).replace('\\\\', '\\\\\\\\').replace('\"', '\\\\\"').replace('\n', '\\\\n')
    print(f'export REQMGMT_OPT_{k.upper()}=\"{safe_v}\"')
" "$config_file"
}

# 从 CWD 向上查找 .requirement-mgmt/config.yaml
find_config() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.requirement-mgmt/config.yaml" ]]; then
            echo "$dir/.requirement-mgmt/config.yaml"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# 列出所有可用 provider（扫描 providers/ 目录）
list_providers() {
    local providers_dir="$1"
    for dir in "$providers_dir"/*/; do
        local name
        name=$(basename "$dir")
        if [[ -f "$dir/provider.yaml" ]]; then
            local display_name
            display_name=$(python3 -c "
import yaml, sys
with open(sys.argv[1]) as f:
    cfg = yaml.safe_load(f)
print(cfg.get('display_name', sys.argv[2]))
" "$dir/provider.yaml" "$name")
            echo "$name|$display_name"
        fi
    done
}
