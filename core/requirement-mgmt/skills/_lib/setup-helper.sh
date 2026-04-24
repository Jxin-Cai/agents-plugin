#!/usr/bin/env bash
set -euo pipefail

LIB_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$0")")" && pwd)"
SKILLS_ROOT="$(cd "$LIB_DIR/.." && pwd)"
PROVIDERS_DIR="$SKILLS_ROOT/_providers"

source "$LIB_DIR/config-reader.sh"

find_project_root() {
  local config_path
  if config_path="$(find_config 2>/dev/null)"; then
    cd "$(dirname "$config_path")/.." && pwd
    return 0
  fi

  if git_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    printf '%s\n' "$git_root"
    return 0
  fi

  printf '%s\n' "$PWD"
}

config_path_for_cwd() {
  local config_path
  if config_path="$(find_config 2>/dev/null)"; then
    printf '%s\n' "$config_path"
    return 0
  fi

  local project_root
  project_root="$(find_project_root)"
  printf '%s/.requirement-mgmt/config.yaml\n' "$project_root"
}

status_cmd() {
  local config_path=""
  local provider=""
  local project_root
  project_root="$(find_project_root)"

  if config_path="$(find_config 2>/dev/null)"; then
    provider="$(read_config_field "$config_path" "provider")"
    cat <<EOF
CONFIG_FOUND=true
CONFIG_PATH=$config_path
PROJECT_ROOT=$project_root
PROVIDER=$provider
EOF
    return 0
  fi

  cat <<EOF
CONFIG_FOUND=false
CONFIG_PATH=
PROJECT_ROOT=$project_root
PROVIDER=
EOF
}

summary_cmd() {
  local config_path="${1:-}"
  if [[ -z "$config_path" ]]; then
    config_path="$(config_path_for_cwd)"
  fi

  if [[ ! -f "$config_path" ]]; then
    echo '{"config_found": false}'
    return 0
  fi

  python3 - "$config_path" <<'PY'
import json
import sys
import yaml
from pathlib import Path

path = Path(sys.argv[1])
cfg = yaml.safe_load(path.read_text()) or {}

def mask(value):
    if value is None:
        return None
    text = str(value)
    if len(text) <= 4:
        return '****'
    return text[:2] + '***' + text[-2:]

masked = {}
for section in ('connection', 'options'):
    data = cfg.get(section) or {}
    out = {}
    for key, value in data.items():
        if key in {'token', 'password', 'secret', 'login_command'}:
            out[key] = mask(value)
        else:
            out[key] = value
    masked[section] = out

print(json.dumps({
    'config_found': True,
    'config_path': str(path),
    'project_root': str(path.parent.parent),
    'provider': cfg.get('provider', ''),
    'connection': masked['connection'],
    'options': masked['options'],
}, ensure_ascii=False))
PY
}

provider_schema_cmd() {
  local provider="${1:?Usage: setup-helper.sh provider-schema <provider>}"
  local provider_file="$PROVIDERS_DIR/$provider/provider.yaml"
  if [[ ! -f "$provider_file" ]]; then
    echo "Provider not found: $provider" >&2
    exit 1
  fi

  python3 - "$provider_file" <<'PY'
import json
import sys
import yaml

path = sys.argv[1]
cfg = yaml.safe_load(open(path)) or {}


def normalize(fields):
    if isinstance(fields, list):
        result = []
        for item in fields:
            result.append({
                'name': item.get('name', ''),
                'type': item.get('type', 'string'),
                'required': bool(item.get('required', False)),
                'secret': bool(item.get('secret', item.get('type') == 'secret')),
                'description': item.get('description', ''),
                'default': item.get('default'),
                'allowed': item.get('allowed'),
            })
        return result

    if isinstance(fields, dict):
        result = []
        for name, item in fields.items():
            item = item or {}
            result.append({
                'name': name,
                'type': item.get('type', 'string'),
                'required': bool(item.get('required', False)),
                'secret': bool(item.get('secret', item.get('type') == 'secret')),
                'description': item.get('description', ''),
                'default': item.get('default'),
                'allowed': item.get('allowed'),
            })
        return result

    return []

print(json.dumps({
    'name': cfg.get('name', ''),
    'display_name': cfg.get('display_name', cfg.get('name', '')),
    'auth_type': cfg.get('auth_type', ''),
    'connection_fields': normalize(cfg.get('connection_fields')),
    'options': normalize(cfg.get('options')),
    'operations': cfg.get('operations', []),
}, ensure_ascii=False))
PY
}

write_config_cmd() {
  local provider="${1:?Usage: setup-helper.sh write-config <provider> <connection-json> <options-json> [config-path]}"
  local connection_json="${2:?Usage: setup-helper.sh write-config <provider> <connection-json> <options-json> [config-path]}"
  local options_json="${3:-}"
  local config_path="${4:-$(config_path_for_cwd)}"

  if [[ -z "$options_json" ]]; then
    options_json='{}'
  fi

  mkdir -p "$(dirname "$config_path")"

  python3 - "$provider" "$connection_json" "$options_json" "$config_path" <<'PY'
import json
import sys
import yaml
from pathlib import Path

provider = sys.argv[1]
connection = json.loads(sys.argv[2])
options = json.loads(sys.argv[3])
out_path = Path(sys.argv[4])

payload = {
    'provider': provider,
    'connection': connection or {},
    'options': options or {},
}

out_path.write_text(yaml.safe_dump(payload, allow_unicode=True, sort_keys=False), encoding='utf-8')
print(str(out_path))
PY
}


ensure_gitignore_cmd() {
  local project_root="${1:-$(find_project_root)}"
  local gitignore_path="$project_root/.gitignore"
  local line='.requirement-mgmt/'

  if [[ ! -f "$gitignore_path" ]]; then
    printf '%s\n' "$line" > "$gitignore_path"
    printf '%s\n' "$gitignore_path"
    return 0
  fi

  if ! grep -Fxq "$line" "$gitignore_path"; then
    printf '\n%s\n' "$line" >> "$gitignore_path"
  fi

  printf '%s\n' "$gitignore_path"
}

COMMAND="${1:-}"
shift || true

case "$COMMAND" in
  status) status_cmd "$@" ;;
  summary) summary_cmd "$@" ;;
  provider-schema) provider_schema_cmd "$@" ;;
  write-config) write_config_cmd "$@" ;;
  ensure-gitignore) ensure_gitignore_cmd "$@" ;;
  config-path) config_path_for_cwd "$@" ;;
  project-root) find_project_root "$@" ;;
  *)
    echo "Usage: setup-helper.sh <status|summary|provider-schema|write-config|ensure-gitignore|config-path|project-root> [args...]" >&2
    exit 1
    ;;
esac
