#!/usr/bin/env bash
# Enforce Ask Buddy's read-only boundary. Only memory files under the current
# project's .ask-buddy/ directory may be changed.

set -u

python3 -c '
import json
import os
import pathlib
import re
import sys

try:
    payload = json.load(sys.stdin)
except Exception:
    print("Ask Buddy 无法验证这次操作，已按只读策略拦截。", file=sys.stderr)
    raise SystemExit(2)

tool = str(payload.get("tool_name", ""))
tool_input = payload.get("tool_input") or {}
cwd = pathlib.Path(payload.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()).resolve()
memory_root = (cwd / ".ask-buddy").resolve()

try:
    memory_root.relative_to(cwd)
except ValueError:
    print(".ask-buddy 不能指向项目目录之外，已按只读策略拦截。", file=sys.stderr)
    raise SystemExit(2)

if tool in {"Write", "Edit", "NotebookEdit"}:
    raw_path = tool_input.get("file_path") or tool_input.get("notebook_path") or ""
    if not raw_path:
        print("Ask Buddy 无法确认写入目标，已按只读策略拦截。", file=sys.stderr)
        raise SystemExit(2)
    target = pathlib.Path(raw_path)
    if not target.is_absolute():
        target = cwd / target
    target = target.resolve(strict=False)
    try:
        target.relative_to(memory_root)
    except ValueError:
        print("Ask Buddy 只允许修改当前项目的 .ask-buddy/ 记忆目录。", file=sys.stderr)
        raise SystemExit(2)
    raise SystemExit(0)

if tool == "Bash":
    print("Ask Buddy 是只读助手，不执行 Bash；请使用 Read、Glob 或 Grep 完成检索。", file=sys.stderr)
    raise SystemExit(2)

if tool.startswith("mcp__"):
    # The bundled OneSearch tools are retrieval-only. For other MCP servers,
    # allow an explicit read vocabulary and deny unknown or mutating actions.
    normalized = tool.lower().replace("-", "_")
    leaf = normalized.rsplit("__", 1)[-1]
    if leaf in {"one_search", "one_scrape", "one_map", "one_extract"}:
        raise SystemExit(0)
    # The local memory server reads only active memory. memory_stage is the one
    # controlled mutation: the server can append only an inert pending item.
    if leaf in {"memory_status", "memory_search", "memory_get", "memory_stage"}:
        raise SystemExit(0)
    feishu_readonly = {
        "feishu_agenda", "feishu_tasks", "feishu_mail_search", "feishu_mail_get",
        "calendar_v4_calendar_primary", "calendar_v4_calendar_event_list",
        "calendar_v4_calendar_event_get", "calendar_v4_calendar_event_search",
        "calendar_v4_calendar_event_instance_view", "calendar_v4_freebusy_list",
        "calendar_v4_calendarevent_list", "calendar_v4_calendarevent_get",
        "calendar_v4_calendarevent_search", "calendar_v4_calendarevent_instanceview",
        "task_v2_task_list", "task_v2_task_get", "task_v2_tasklist_list",
        "task_v2_tasklist_get", "task_v2_tasklist_tasks", "task_v2_task_subtask_list",
        "task_v2_tasksubtask_list",
    }
    if leaf in feishu_readonly:
        raise SystemExit(0)
    read_prefixes = (
        "read", "get", "list", "search", "find", "fetch", "query",
        "view", "lookup", "retrieve", "inspect", "browse", "check",
    )
    mutating = re.search(r"(^|_)(add|create|delete|edit|move|post|publish|remove|rename|send|update|upload|write)(_|$)", leaf)
    if leaf.startswith(read_prefixes) and not mutating:
        raise SystemExit(0)
    print("Ask Buddy 只允许调用只读 MCP 工具；该工具未通过只读白名单。", file=sys.stderr)
    raise SystemExit(2)

raise SystemExit(0)
'
