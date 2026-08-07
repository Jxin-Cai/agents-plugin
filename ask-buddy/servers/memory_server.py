#!/usr/bin/env python3
"""Local-only MCP server for Ask Buddy's layered Markdown memory.

The server intentionally has no network access and only one mutating tool:
memory_stage, which appends an inert candidate to memory/pending.md.
"""

from __future__ import annotations

import datetime as dt
import json
import math
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any, Iterable


SERVER_NAME = "ask-buddy-memory"
SERVER_VERSION = "1.0.0"
MAX_FILE_BYTES = 1_000_000
MAX_GET_LINES = 200
MAX_GET_CHARS = 12_000


class MemoryError(ValueError):
    """A safe, user-facing memory error."""


def project_root() -> Path:
    configured = os.environ.get("ASK_BUDDY_PROJECT_DIR", "")
    if configured.startswith("${"):
        configured = ""
    return Path(configured or os.getcwd()).resolve()


def memory_root(root: Path) -> Path:
    root = root.resolve()
    raw = root / ".ask-buddy"
    if raw.is_symlink():
        raise MemoryError(".ask-buddy 不能是符号链接")
    resolved = raw.resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise MemoryError(".ask-buddy 必须位于当前项目内") from exc
    return resolved


def allowed_files(root: Path) -> list[Path]:
    root = root.resolve()
    base = memory_root(root)
    memory = base / "memory"
    if memory.is_symlink():
        raise MemoryError("memory 目录不能是符号链接")
    files = [
        base / "session-context.md",
        memory / "profile.md",
        memory / "memory.md",
        memory / "playbook.md",
        memory / "topics.md",
        memory / "insights.md",
        memory / "instincts.md",
    ]
    daily = memory / "daily"
    if daily.is_dir() and not daily.is_symlink():
        files.extend(sorted(p for p in daily.glob("*.md") if not p.is_symlink()))
    return [p for p in files if p.is_file() and not p.is_symlink()]


def relative_name(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def safe_read(path: Path) -> str:
    if path.stat().st_size > MAX_FILE_BYTES:
        raise MemoryError(f"记忆文件过大，拒绝读取：{path.name}")
    return path.read_text(encoding="utf-8", errors="replace")


def chunks(path: Path, root: Path) -> Iterable[dict[str, Any]]:
    text = safe_read(path)
    lines = text.splitlines()
    starts = [i for i, line in enumerate(lines) if re.match(r"^#{1,2}\s+", line)]
    if not starts:
        starts = [0]
    elif starts[0] != 0:
        starts.insert(0, 0)
    for pos, start in enumerate(starts):
        end = starts[pos + 1] if pos + 1 < len(starts) else len(lines)
        body = "\n".join(lines[start:end]).strip()
        if not body or re.search(r"\*\*status\*\*:\s*(superseded|retired)", body, re.I):
            continue
        yield {
            "path": relative_name(path, root),
            "line": start + 1,
            "text": body,
        }


def terms(value: str) -> set[str]:
    lowered = value.casefold()
    latin = re.findall(r"[a-z0-9][a-z0-9_.:/-]*", lowered)
    cjk_runs = re.findall(r"[\u3400-\u9fff]+", lowered)
    cjk: list[str] = []
    for run in cjk_runs:
        if len(run) == 1:
            cjk.append(run)
        else:
            cjk.extend(run[i : i + 2] for i in range(len(run) - 1))
    return set(latin + cjk)


def recency_score(path: str, today: dt.date) -> float:
    match = re.search(r"/daily/(\d{4}-\d{2}-\d{2})\.md$", path)
    if not match:
        return 0.35 if path.endswith(("profile.md", "memory.md", "playbook.md")) else 0.15
    try:
        age = max(0, (today - dt.date.fromisoformat(match.group(1))).days)
    except ValueError:
        return 0.0
    return math.exp(-age / 14.0)


def importance_score(text: str) -> float:
    match = re.search(r"\*\*importance\*\*:\s*([123])", text, re.I)
    return {"1": 0.0, "2": 0.25, "3": 0.5}.get(match.group(1) if match else "", 0.0)


def search_memory(root: Path, query: str, limit: int = 5, today: dt.date | None = None) -> dict[str, Any]:
    root = root.resolve()
    query = query.strip()
    if not query or len(query) > 500:
        raise MemoryError("query 必须为 1–500 个字符")
    if not 1 <= limit <= 10:
        raise MemoryError("limit 必须在 1–10 之间")
    qterms = terms(query)
    if not qterms:
        raise MemoryError("query 不包含可检索关键词")
    today = today or dt.date.today()
    candidates: list[dict[str, Any]] = []
    for path in allowed_files(root):
        for item in chunks(path, root):
            body = item["text"]
            bterms = terms(body)
            overlap = qterms & bterms
            exact = query.casefold() in body.casefold()
            if not overlap and not exact:
                continue
            relevance = len(overlap) / max(1, len(qterms))
            score = relevance * 4.0 + (1.5 if exact else 0.0)
            score += recency_score(item["path"], today) + importance_score(body)
            item["score"] = round(score, 3)
            item["excerpt"] = re.sub(r"\s+", " ", body)[:500]
            del item["text"]
            candidates.append(item)
    candidates.sort(key=lambda item: (-item["score"], item["path"], item["line"]))
    selected: list[dict[str, Any]] = []
    per_file: dict[str, int] = {}
    for item in candidates:
        if per_file.get(item["path"], 0) >= 2:
            continue
        selected.append(item)
        per_file[item["path"]] = per_file.get(item["path"], 0) + 1
        if len(selected) >= limit:
            break
    return {"query": query, "count": len(selected), "results": selected}


def resolve_get_path(root: Path, requested: str) -> Path:
    root = root.resolve()
    requested = requested.strip()
    if not requested:
        raise MemoryError("path 不能为空")
    candidate = Path(requested)
    if not candidate.is_absolute():
        candidate = root / candidate
    resolved = candidate.resolve(strict=False)
    allowed = {p.resolve(): p for p in allowed_files(root)}
    if resolved not in allowed:
        raise MemoryError("只能读取已激活的 Ask Buddy 记忆文件；pending 和备份不可读取")
    return allowed[resolved]


def get_memory(root: Path, requested: str, start_line: int = 1, end_line: int | None = None) -> dict[str, Any]:
    root = root.resolve()
    path = resolve_get_path(root, requested)
    if start_line < 1:
        raise MemoryError("start_line 必须大于 0")
    lines = safe_read(path).splitlines()
    final = min(len(lines), end_line if end_line is not None else start_line + MAX_GET_LINES - 1)
    if final < start_line or final - start_line + 1 > MAX_GET_LINES:
        raise MemoryError(f"单次最多读取 {MAX_GET_LINES} 行")
    content = "\n".join(lines[start_line - 1 : final])
    if len(content) > MAX_GET_CHARS:
        content = content[:MAX_GET_CHARS] + "\n[已按字符上限截断]"
    return {"path": relative_name(path, root), "start_line": start_line, "end_line": final, "content": content}


def status(root: Path) -> dict[str, Any]:
    root = root.resolve()
    base = memory_root(root)
    files = allowed_files(root)
    pending = base / "memory" / "pending.md"
    pending_count = 0
    if pending.is_file() and not pending.is_symlink() and pending.stat().st_size <= MAX_FILE_BYTES:
        pending_count = len(re.findall(r"^## PENDING-\d+", safe_read(pending), re.M))
    limits = {"profile.md": 3000, "memory.md": 6000, "playbook.md": 6000}
    details = []
    warnings = []
    for path in files:
        size = path.stat().st_size
        chars = len(safe_read(path))
        name = relative_name(path, root)
        details.append({"path": name, "bytes": size, "characters": chars})
        limit = limits.get(path.name)
        if limit and chars > limit:
            warnings.append(f"{name} 超过建议上限 {limit} 字符")
    return {"local_only": True, "active_files": len(files), "pending_count": pending_count, "files": details, "warnings": warnings}


def clean_field(arguments: dict[str, Any], name: str, maximum: int) -> str:
    value = re.sub(r"\s+", " ", str(arguments.get(name, "")).strip())
    if not value or len(value) > maximum:
        raise MemoryError(f"{name} 必须为 1–{maximum} 个字符")
    return value


def stage_memory(root: Path, arguments: dict[str, Any]) -> dict[str, Any]:
    root = root.resolve()
    target = str(arguments.get("target", ""))
    confidence = str(arguments.get("confidence", ""))
    if target not in {"profile", "memory", "playbook"}:
        raise MemoryError("target 必须是 profile、memory 或 playbook")
    if confidence not in {"low", "medium", "high"}:
        raise MemoryError("confidence 必须是 low、medium 或 high")
    proposal = clean_field(arguments, "proposal", 1500)
    reason = clean_field(arguments, "reason", 1000)
    evidence = clean_field(arguments, "evidence", 1500)
    base = memory_root(root)
    directory = base / "memory"
    directory.mkdir(parents=True, exist_ok=True)
    if directory.is_symlink():
        raise MemoryError("memory 目录不能是符号链接")
    pending = directory / "pending.md"
    if pending.is_symlink():
        raise MemoryError("pending.md 不能是符号链接")
    existing = safe_read(pending) if pending.exists() else "# Pending Memory\n"
    ids = [int(value) for value in re.findall(r"^## PENDING-(\d+)", existing, re.M)]
    candidate_id = f"PENDING-{max(ids, default=0) + 1:03d}"
    block = (
        f"\n\n## {candidate_id}: candidate\n"
        f"- **target**: {target}\n- **proposal**: {proposal}\n- **reason**: {reason}\n"
        f"- **evidence**: {evidence}\n- **confidence**: {confidence}\n"
        f"- **created**: {dt.date.today().isoformat()}\n- **review_after**: next-related-task\n"
    )
    directory.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=".pending-", suffix=".tmp", dir=directory)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(existing.rstrip() + block + "\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, pending)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)
    return {"id": candidate_id, "status": "pending", "active": False, "path": relative_name(pending, root)}


TOOLS = [
    {
        "name": "memory_status",
        "description": "查看本项目 Ask Buddy 本地记忆的文件规模、待确认数量和容量警告，不返回待确认内容。",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    {
        "name": "memory_search",
        "description": "在已激活的分层记忆中做本地混合检索。自动排除 pending、备份和 superseded 条目。",
        "inputSchema": {
            "type": "object",
            "properties": {"query": {"type": "string", "maxLength": 500}, "limit": {"type": "integer", "minimum": 1, "maximum": 10, "default": 5}},
            "required": ["query"],
            "additionalProperties": False,
        },
    },
    {
        "name": "memory_get",
        "description": "按路径和行号精确读取一段已激活记忆；拒绝 pending、备份、越界路径和符号链接。",
        "inputSchema": {
            "type": "object",
            "properties": {"path": {"type": "string"}, "start_line": {"type": "integer", "minimum": 1, "default": 1}, "end_line": {"type": "integer", "minimum": 1}},
            "required": ["path"],
            "additionalProperties": False,
        },
    },
    {
        "name": "memory_stage",
        "description": "把模型推断或程序经验暂存到 pending 队列，等待用户批准；不会形成有效记忆。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "target": {"type": "string", "enum": ["profile", "memory", "playbook"]},
                "proposal": {"type": "string", "maxLength": 1500},
                "reason": {"type": "string", "maxLength": 1000},
                "evidence": {"type": "string", "maxLength": 1500},
                "confidence": {"type": "string", "enum": ["low", "medium", "high"]},
            },
            "required": ["target", "proposal", "reason", "evidence", "confidence"],
            "additionalProperties": False,
        },
    },
]


def call_tool(name: str, arguments: dict[str, Any], root: Path) -> dict[str, Any]:
    if name == "memory_status":
        return status(root)
    if name == "memory_search":
        return search_memory(root, str(arguments.get("query", "")), int(arguments.get("limit", 5)))
    if name == "memory_get":
        return get_memory(root, str(arguments.get("path", "")), int(arguments.get("start_line", 1)), arguments.get("end_line"))
    if name == "memory_stage":
        return stage_memory(root, arguments)
    raise MemoryError(f"未知工具：{name}")


def rpc_result(request_id: Any, result: Any) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def handle(message: dict[str, Any], root: Path) -> dict[str, Any] | None:
    method = message.get("method")
    request_id = message.get("id")
    if request_id is None:
        return None
    if method == "initialize":
        requested = (message.get("params") or {}).get("protocolVersion", "2025-11-25")
        return rpc_result(request_id, {"protocolVersion": requested, "capabilities": {"tools": {"listChanged": False}}, "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION}})
    if method == "server/discover":
        return rpc_result(request_id, {
            "resultType": "complete",
            "supportedVersions": ["2026-07-28"],
            "capabilities": {"tools": {}},
            "_meta": {"io.modelcontextprotocol/serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION}},
            "instructions": "Local layered memory retrieval. Pending candidates are inert until the user approves them.",
            "ttlMs": 300_000,
            "cacheScope": "private",
        })
    if method == "ping":
        return rpc_result(request_id, {})
    if method == "tools/list":
        return rpc_result(request_id, {"resultType": "complete", "tools": TOOLS, "ttlMs": 300_000, "cacheScope": "private"})
    if method == "tools/call":
        params = message.get("params") or {}
        try:
            value = call_tool(str(params.get("name", "")), params.get("arguments") or {}, root)
            result = {"resultType": "complete", "content": [{"type": "text", "text": json.dumps(value, ensure_ascii=False)}], "isError": False}
        except (MemoryError, OSError, TypeError, ValueError) as exc:
            result = {"resultType": "complete", "content": [{"type": "text", "text": str(exc)}], "isError": True}
        return rpc_result(request_id, result)
    return {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32601, "message": "Method not found"}}


def main() -> None:
    root = project_root()
    for raw in sys.stdin:
        try:
            message = json.loads(raw)
            response = handle(message, root)
        except (json.JSONDecodeError, TypeError) as exc:
            response = {"jsonrpc": "2.0", "id": None, "error": {"code": -32700, "message": f"Parse error: {exc}"}}
        if response is not None:
            sys.stdout.write(json.dumps(response, ensure_ascii=False, separators=(",", ":")) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
