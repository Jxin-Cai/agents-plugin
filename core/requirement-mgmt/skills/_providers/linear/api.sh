#!/usr/bin/env bash
# Linear provider adapter (stub)
# All operations are placeholders pending implementation.
set -euo pipefail

op_not_implemented() {
  local op="$1"
  echo "Linear ${op}: not yet implemented" >&2
  exit 2
}

op_not_supported() {
  local op="$1"
  echo "Operation not supported for Linear: ${op}" >&2
  exit 2
}

OPERATION="${1:-}"
shift || true

case "$OPERATION" in
  fetch)       op_not_implemented "fetch" ;;
  comment)     op_not_implemented "comment" ;;
  search)      op_not_implemented "search" ;;
  transitions) op_not_supported "transitions" ;;
  transition)  op_not_supported "transition" ;;
  attach)      op_not_supported "attach" ;;
  *)
    echo "Usage: api.sh <fetch|comment|search> [args...]" >&2
    exit 1
    ;;
esac
