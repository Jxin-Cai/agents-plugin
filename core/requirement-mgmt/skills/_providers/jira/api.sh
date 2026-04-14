#!/usr/bin/env bash
# Jira Server / Data Center API adapter
# Implements: fetch, comment, transitions, transition, attach, search, create, update
set -euo pipefail

###############################################################################
# Credential resolution
#   Priority: REQMGMT_* env  →  REQMGMT_*_ENV indirection  →  legacy JIRA_*
###############################################################################

resolve_var() {
  local name="$1" env_name="${1}_ENV" legacy="$2"
  local val="${!name:-}"
  if [[ -z "$val" ]]; then
    local indirect="${!env_name:-}"
    if [[ -n "$indirect" ]]; then
      val="${!indirect:-}"
    fi
  fi
  if [[ -z "$val" && -n "$legacy" ]]; then
    val="${!legacy:-}"
  fi
  echo "$val"
}

BASE_URL="$(resolve_var REQMGMT_BASE_URL JIRA_BASE_URL)"
TOKEN="$(resolve_var REQMGMT_TOKEN JIRA_TOKEN)"
SSL_VERIFY="$(resolve_var REQMGMT_SSL_VERIFY "")"
API_VERSION="${REQMGMT_OPT_API_VERSION:-2}"

# Strip trailing slash from base URL
BASE_URL="${BASE_URL%/}"

if [[ -z "$BASE_URL" || -z "$TOKEN" ]]; then
  echo "ERROR: REQMGMT_BASE_URL and REQMGMT_TOKEN (or JIRA_BASE_URL/JIRA_TOKEN) must be set." >&2
  exit 1
fi

###############################################################################
# Helpers
###############################################################################

CURL_OPTS=(-s -S --fail-with-body)

if [[ "${SSL_VERIFY,,}" == "false" || "${SSL_VERIFY}" == "0" ]]; then
  CURL_OPTS+=(--insecure)
fi

api_get() {
  curl "${CURL_OPTS[@]}" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "$BASE_URL/rest/api/${API_VERSION}/$1"
}

api_post() {
  curl "${CURL_OPTS[@]}" \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$2" \
    "$BASE_URL/rest/api/${API_VERSION}/$1"
}

api_put() {
  curl "${CURL_OPTS[@]}" \
    -X PUT \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$2" \
    "$BASE_URL/rest/api/${API_VERSION}/$1"
}

api_post_file() {
  curl "${CURL_OPTS[@]}" \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @"$2" \
    "$BASE_URL/rest/api/${API_VERSION}/$1"
}

api_put_file() {
  curl "${CURL_OPTS[@]}" \
    -X PUT \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d @"$2" \
    "$BASE_URL/rest/api/${API_VERSION}/$1"
}

json_val() {
  # $1 = json string, $2 = python expression on obj 'o'
  python3 -c "
import json, sys
o = json.loads(sys.stdin.read())
val = $2
print(val if val is not None else '')
" <<< "$1"
}

json_lines() {
  python3 -c "
import json, sys
o = json.loads(sys.stdin.read())
$2
" <<< "$1"
}

###############################################################################
# Operations
###############################################################################

op_fetch() {
  local issue_id="$1"
  local issue_json
  issue_json="$(api_get "issue/${issue_id}?expand=transitions,changelog")"

  local comments_json
  comments_json="$(api_get "issue/${issue_id}/comment")" || comments_json='{"comments":[]}'

  python3 -c "
import json, sys, textwrap

issue = json.loads(sys.argv[1])
comments_data = json.loads(sys.argv[2])

fields = issue.get('fields', {})
key = issue.get('key', 'N/A')
summary = fields.get('summary', 'N/A')

status_obj = fields.get('status') or {}
status = status_obj.get('name', 'N/A')

assignee_obj = fields.get('assignee') or {}
assignee = assignee_obj.get('displayName', 'Unassigned')

priority_obj = fields.get('priority') or {}
priority = priority_obj.get('name', 'N/A')

issuetype_obj = fields.get('issuetype') or {}
issuetype = issuetype_obj.get('name', 'N/A')

description = fields.get('description') or '(no description)'

print(f'# {key}: {summary}')
print()
print(f'| Field | Value |')
print(f'|-------|-------|')
print(f'| Status | {status} |')
print(f'| Assignee | {assignee} |')
print(f'| Priority | {priority} |')
print(f'| Type | {issuetype} |')
print()

# Description
print('## Description')
print()
print(description)
print()

# Linked Issues
links = fields.get('issuelinks') or []
if links:
    print('## Linked Issues')
    print()
    for link in links:
        link_type = link.get('type', {}).get('name', '')
        if 'outwardIssue' in link:
            target = link['outwardIssue']
            direction = link.get('type', {}).get('outward', link_type)
        elif 'inwardIssue' in link:
            target = link['inwardIssue']
            direction = link.get('type', {}).get('inward', link_type)
        else:
            continue
        tkey = target.get('key', '')
        tsum = target.get('fields', {}).get('summary', '')
        print(f'- **{direction}** {tkey}: {tsum}')
    print()

# Attachments
attachments = fields.get('attachment') or []
if attachments:
    print('## Attachments')
    print()
    for att in attachments:
        name = att.get('filename', 'unknown')
        url = att.get('content', '')
        size = att.get('size', 0)
        size_kb = round(size / 1024, 1)
        print(f'- [{name}]({url}) ({size_kb} KB)')
    print()

# Comments
comments = comments_data.get('comments') or []
if comments:
    print('## Comments')
    print()
    for c in comments:
        author = (c.get('author') or {}).get('displayName', 'Unknown')
        created = c.get('created', '')[:10]
        body = c.get('body', '')
        print(f'### {author} — {created}')
        print()
        print(body)
        print()
" "$issue_json" "$comments_json"
}

op_comment() {
  local issue_id="$1"
  shift
  local body="$*"
  if [[ -z "$body" ]]; then
    echo "ERROR: comment body is required." >&2
    exit 1
  fi
  local payload
  payload="$(python3 -c "import json; print(json.dumps({'body': '''$body'''}))")" 2>/dev/null \
    || payload="{\"body\": $(python3 -c "import json,sys; print(json.dumps(sys.argv[1]))" "$body")}"
  local result
  result="$(api_post "issue/${issue_id}/comment" "$payload")"
  echo "Comment added to ${issue_id} successfully."
}

op_transitions() {
  local issue_id="$1"
  local json
  json="$(api_get "issue/${issue_id}/transitions")"
  json_lines "$json" "
for t in o.get('transitions', []):
    print(f\"{t['id']}: {t['name']}\")
"
}

op_transition() {
  local issue_id="$1"
  local target_status="$2"

  # Fetch available transitions
  local trans_json
  trans_json="$(api_get "issue/${issue_id}/transitions")"

  # Resolve target status name to transition ID (case-insensitive)
  local transition_id
  transition_id="$(python3 -c "
import json, sys
data = json.loads(sys.argv[1])
target = sys.argv[2].strip().lower()
for t in data.get('transitions', []):
    if t['name'].strip().lower() == target:
        print(t['id'])
        sys.exit(0)
# Also try matching by ID directly
for t in data.get('transitions', []):
    if str(t['id']) == sys.argv[2].strip():
        print(t['id'])
        sys.exit(0)
print('')
" "$trans_json" "$target_status")"

  if [[ -z "$transition_id" ]]; then
    echo "ERROR: No transition found matching '${target_status}'." >&2
    echo "Available transitions:" >&2
    json_lines "$trans_json" "
for t in o.get('transitions', []):
    print(f\"  {t['id']}: {t['name']}\", file=sys.stderr)
" 2>&1 >&2
    exit 1
  fi

  local payload="{\"transition\":{\"id\":\"${transition_id}\"}}"
  api_post "issue/${issue_id}/transitions" "$payload" > /dev/null
  echo "Transitioned ${issue_id} to '${target_status}' (transition ID: ${transition_id})."
}

op_attach() {
  local issue_id="$1"
  local filepath="$2"

  if [[ ! -f "$filepath" ]]; then
    echo "ERROR: File not found: ${filepath}" >&2
    exit 1
  fi

  curl "${CURL_OPTS[@]}" \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-Atlassian-Token: no-check" \
    -F "file=@${filepath}" \
    "$BASE_URL/rest/api/${API_VERSION}/issue/${issue_id}/attachments" > /dev/null

  echo "Attached '$(basename "$filepath")' to ${issue_id} successfully."
}

op_search() {
  local jql="$*"
  if [[ -z "$jql" ]]; then
    echo "ERROR: JQL query is required." >&2
    exit 1
  fi

  local payload
  payload="$(python3 -c "
import json, sys
print(json.dumps({
    'jql': sys.argv[1],
    'maxResults': 20,
    'fields': ['summary', 'status', 'assignee', 'priority', 'issuetype']
}))
" "$jql")"

  local result
  # Jira Cloud 已废弃 POST /rest/api/{2,3}/search (410 Gone)
  # 新端点: POST /rest/api/3/search/jql (仅 Cloud)
  # Server/DC 仍用旧端点，故先尝试新端点，失败时回退
  result="$(curl "${CURL_OPTS[@]}" \
    -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$BASE_URL/rest/api/3/search/jql" 2>/dev/null)" || \
  result="$(api_post "search" "$payload")"

  python3 -c "
import json, sys

data = json.loads(sys.stdin.read())
issues = data.get('issues', [])

if not issues:
    print('No issues found.')
    sys.exit(0)

# /search/jql 不返回 total，用 isLast 判断是否还有更多
if 'total' in data:
    print(f\"Found {data['total']} issue(s) (showing {len(issues)}):\")
elif data.get('isLast', True):
    print(f'Found {len(issues)} issue(s):')
else:
    print(f'Showing {len(issues)} issue(s) (more available):')
print()
print('| Key | Type | Summary | Status | Assignee | Priority |')
print('|-----|------|---------|--------|----------|----------|')
for i in issues:
    key = i.get('key', '')
    f = i.get('fields', {})
    itype = (f.get('issuetype') or {}).get('name', '')
    summary = f.get('summary', '')
    if len(summary) > 60:
        summary = summary[:57] + '...'
    status = (f.get('status') or {}).get('name', '')
    assignee = (f.get('assignee') or {}).get('displayName', 'Unassigned')
    priority = (f.get('priority') or {}).get('name', '')
    print(f'| {key} | {itype} | {summary} | {status} | {assignee} | {priority} |')
" <<< "$result"
}

op_create() {
  local json_file="$1"

  if [[ ! -f "$json_file" ]]; then
    echo "ERROR: JSON file not found: ${json_file}" >&2
    exit 1
  fi

  local result
  result="$(api_post_file "issue" "$json_file")"

  python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
key = data.get('key', '')
issue_id = data.get('id', '')
print(f'{key}')
" <<< "$result"
}

op_update() {
  local issue_id="$1"
  local json_file="$2"

  if [[ ! -f "$json_file" ]]; then
    echo "ERROR: JSON file not found: ${json_file}" >&2
    exit 1
  fi

  api_put_file "issue/${issue_id}" "$json_file" > /dev/null
  echo "Updated ${issue_id} successfully."
}

###############################################################################
# Dispatch
###############################################################################

OPERATION="${1:-}"
shift || true

case "$OPERATION" in
  fetch)
    [[ -z "${1:-}" ]] && { echo "Usage: api.sh fetch <ISSUE_ID>" >&2; exit 1; }
    op_fetch "$1"
    ;;
  comment)
    [[ -z "${1:-}" ]] && { echo "Usage: api.sh comment <ISSUE_ID> <BODY>" >&2; exit 1; }
    issue_id="$1"; shift
    op_comment "$issue_id" "$@"
    ;;
  transitions)
    [[ -z "${1:-}" ]] && { echo "Usage: api.sh transitions <ISSUE_ID>" >&2; exit 1; }
    op_transitions "$1"
    ;;
  transition)
    [[ -z "${1:-}" || -z "${2:-}" ]] && { echo "Usage: api.sh transition <ISSUE_ID> <STATUS>" >&2; exit 1; }
    op_transition "$1" "$2"
    ;;
  attach)
    [[ -z "${1:-}" || -z "${2:-}" ]] && { echo "Usage: api.sh attach <ISSUE_ID> <FILE_PATH>" >&2; exit 1; }
    op_attach "$1" "$2"
    ;;
  search)
    [[ -z "${1:-}" ]] && { echo "Usage: api.sh search <JQL>" >&2; exit 1; }
    op_search "$@"
    ;;
  create)
    [[ -z "${1:-}" ]] && { echo "Usage: api.sh create <JSON_FILE>" >&2; exit 1; }
    op_create "$1"
    ;;
  update)
    [[ -z "${1:-}" || -z "${2:-}" ]] && { echo "Usage: api.sh update <ISSUE_ID> <JSON_FILE>" >&2; exit 1; }
    op_update "$1" "$2"
    ;;
  *)
    echo "Jira provider — supported operations: fetch, comment, transitions, transition, attach, search, create, update" >&2
    echo "Usage: api.sh <operation> [args...]" >&2
    exit 1
    ;;
esac
