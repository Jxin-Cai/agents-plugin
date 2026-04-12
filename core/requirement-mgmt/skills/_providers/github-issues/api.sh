#!/usr/bin/env bash
# GitHub Issues provider adapter
# Uses the gh CLI for all GitHub API interactions.
set -euo pipefail

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
# REQMGMT_TOKEN or indirection via REQMGMT_TOKEN_ENV
if [[ -n "${REQMGMT_TOKEN_ENV:-}" ]]; then
  export GH_TOKEN="${!REQMGMT_TOKEN_ENV}"
elif [[ -n "${REQMGMT_TOKEN:-}" ]]; then
  export GH_TOKEN="$REQMGMT_TOKEN"
fi
# If neither is set, gh CLI uses its own logged-in session.

REPO="${REQMGMT_REPO:-}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
require_gh() {
  if ! command -v gh &>/dev/null; then
    echo "Error: gh CLI is not installed. Install from https://cli.github.com" >&2
    exit 1
  fi
}

# Parse an issue reference into REPO and ISSUE_NUM.
# Accepted formats: 123, #123, owner/repo#123
parse_issue_ref() {
  local ref="$1"

  if [[ "$ref" =~ ^([A-Za-z0-9._-]+/[A-Za-z0-9._-]+)#([0-9]+)$ ]]; then
    REPO="${BASH_REMATCH[1]}"
    ISSUE_NUM="${BASH_REMATCH[2]}"
  elif [[ "$ref" =~ ^#?([0-9]+)$ ]]; then
    ISSUE_NUM="${BASH_REMATCH[1]}"
  else
    echo "Error: invalid issue reference '$ref'. Use 123, #123, or owner/repo#123" >&2
    exit 1
  fi

  if [[ -z "$REPO" ]]; then
    echo "Error: no repo specified. Set REQMGMT_REPO or use owner/repo#123 format" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Operations
# ---------------------------------------------------------------------------
op_fetch() {
  local ref="${1:?Usage: api.sh fetch <issue-ref>}"
  parse_issue_ref "$ref"

  local json
  json=$(gh issue view "$ISSUE_NUM" \
    --repo "$REPO" \
    --json number,title,state,author,assignees,labels,milestone,body,comments)

  echo "$json" | python3 -c '
import json, sys

d = json.load(sys.stdin)

assignees = ", ".join(a["login"] for a in d.get("assignees") or []) or "None"
labels = ", ".join(l["name"] for l in d.get("labels") or []) or "None"
milestone = (d.get("milestone") or {}).get("title") or "None"
author = (d.get("author") or {}).get("login") or "Unknown"

print(f"# #{d[\"number\"]} {d[\"title\"]}")
print()
print(f"- **State:** {d[\"state\"]}")
print(f"- **Author:** {author}")
print(f"- **Assignees:** {assignees}")
print(f"- **Labels:** {labels}")
print(f"- **Milestone:** {milestone}")
print()
print("## Description")
print()
print(d.get("body") or "_No description._")
print()

comments = d.get("comments") or []
if comments:
    print(f"## Comments ({len(comments)})")
    print()
    for i, c in enumerate(comments, 1):
        c_author = (c.get("author") or {}).get("login") or "Unknown"
        created = c.get("createdAt", "")[:10]
        print(f"### Comment {i} by {c_author} ({created})")
        print()
        print(c.get("body", ""))
        print()
'
}

op_comment() {
  local ref="${1:?Usage: api.sh comment <issue-ref> <body>}"
  local body="${2:?Usage: api.sh comment <issue-ref> <body>}"
  parse_issue_ref "$ref"

  gh issue comment "$ISSUE_NUM" --repo "$REPO" --body "$body"
  echo "Comment added to #${ISSUE_NUM} in ${REPO}."
}

op_search() {
  local query="${1:-}"

  if [[ -z "$REPO" ]]; then
    echo "Error: no repo specified. Set REQMGMT_REPO for search." >&2
    exit 1
  fi

  local args=(issue list --repo "$REPO" --limit 20 --json number,title,state,author,labels,updatedAt)
  if [[ -n "$query" ]]; then
    args+=(--search "$query")
  fi

  gh "${args[@]}" | python3 -c '
import json, sys

issues = json.load(sys.stdin)
if not issues:
    print("No issues found.")
    sys.exit(0)

print("| # | Title | State | Author | Labels | Updated |")
print("|---|-------|-------|--------|--------|---------|")
for i in issues:
    num = i["number"]
    title = i["title"][:60]
    state = i["state"]
    author = (i.get("author") or {}).get("login") or ""
    labels = ", ".join(l["name"] for l in i.get("labels") or [])
    updated = i.get("updatedAt", "")[:10]
    print(f"| #{num} | {title} | {state} | {author} | {labels} | {updated} |")
'
}

op_not_supported() {
  local op="$1"
  echo "Operation not supported for GitHub Issues: ${op}" >&2
  exit 2
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
require_gh

OPERATION="${1:-}"
shift || true

case "$OPERATION" in
  fetch)       op_fetch "$@" ;;
  comment)     op_comment "$@" ;;
  search)      op_search "$@" ;;
  transitions) op_not_supported "transitions" ;;
  transition)  op_not_supported "transition" ;;
  attach)      op_not_supported "attach" ;;
  *)
    echo "Usage: api.sh <fetch|comment|search> [args...]" >&2
    exit 1
    ;;
esac
