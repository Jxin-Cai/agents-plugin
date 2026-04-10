#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(dirname "$SCRIPT_DIR")"

mkdir -p _growth-hacking

cat "$PLUGIN_DIR/skills/gh/references/growth-hacker-agent.md"
