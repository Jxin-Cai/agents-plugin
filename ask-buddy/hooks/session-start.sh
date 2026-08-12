#!/usr/bin/env bash
# Compatibility wrapper; hooks.json invokes the Python implementation directly.
exec python3 "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.py"
