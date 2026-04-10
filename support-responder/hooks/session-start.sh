#!/usr/bin/env bash
set -euo pipefail

mkdir -p _support

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cat "$PLUGIN_DIR/skills/sr/references/support-responder-agent.md"
