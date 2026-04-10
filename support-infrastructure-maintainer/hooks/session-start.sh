#!/usr/bin/env bash
set -euo pipefail

mkdir -p _infrastructure

PLUGIN_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AGENT_REF="$PLUGIN_DIR/skills/sim/references/infrastructure-maintainer-agent.md"

if [ -f "$AGENT_REF" ]; then
  cat "$AGENT_REF"
fi
