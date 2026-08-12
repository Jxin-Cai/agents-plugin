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
raw_cwd = pathlib.Path(payload.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()).expanduser()
if not raw_cwd.is_absolute():
    raw_cwd = pathlib.Path(os.path.abspath(raw_cwd))
cwd = raw_cwd.resolve()
raw_memory_root = cwd / ".ask-buddy"
if raw_memory_root.is_symlink():
    print(".ask-buddy 不能是符号链接，已按只读策略拦截。", file=sys.stderr)
    raise SystemExit(2)
memory_root = raw_memory_root.resolve()

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
    if target.is_absolute():
        try:
            relative_target = target.relative_to(raw_cwd)
        except ValueError:
            try:
                relative_target = target.relative_to(cwd)
            except ValueError:
                print("Ask Buddy 只允许修改当前项目的 .ask-buddy/ 记忆目录。", file=sys.stderr)
                raise SystemExit(2)
        lexical_target = cwd / relative_target
    else:
        lexical_target = cwd / target
    lexical_target = pathlib.Path(os.path.normpath(lexical_target))
    try:
        lexical_target.relative_to(raw_memory_root)
    except ValueError:
        print("Ask Buddy 只允许修改当前项目的 .ask-buddy/ 记忆目录。", file=sys.stderr)
        raise SystemExit(2)
    current = raw_memory_root
    for part in lexical_target.relative_to(raw_memory_root).parts:
        current = current / part
        if current.is_symlink():
            print("Ask Buddy 不允许通过记忆目录中的符号链接写入。", file=sys.stderr)
            raise SystemExit(2)
    target = lexical_target.resolve(strict=False)
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
    # The local memory server reads active memory and supports a narrow review
    # workflow: stage/list candidates, then approve/reject only on user request.
    if leaf in {
        "memory_status", "memory_search", "memory_get", "memory_stage",
        "learning_stage", "learning_pending", "learning_decide",
    }:
        raise SystemExit(0)
    feishu_readonly = {
        "feishu_agenda", "feishu_tasks", "feishu_mail_search", "feishu_mail_get", "feishu_freebusy",
        "feishu_binding_preflight", "feishu_binding_status", "feishu_binding_start", "feishu_binding_complete",
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
