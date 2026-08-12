#!/usr/bin/env python3
"""Local-only MCP server for Ask Buddy's layered Markdown memory.

The server intentionally has no network access. New memories are first written
as inert candidates and only move into active Markdown after explicit review.
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
SERVER_VERSION = "1.1.0"
MAX_FILE_BYTES = 1_000_000
MAX_GET_LINES = 200
MAX_GET_CHARS = 12_000
ACTIVE_CHAR_LIMITS = {"profile": 3000, "memory": 6000, "playbook": 6000}
ACTIVE_MEMORY_FILES = {"profile": "profile.md", "memory": "memory.md", "playbook": "playbook.md"}


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


def ensure_memory_directory(root: Path) -> Path:
    base = memory_root(root)
    memory = base / "memory"
    if memory.is_symlink():
        raise MemoryError("memory 目录不能是符号链接")
    base.mkdir(parents=True, exist_ok=True, mode=0o700)
    memory.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(base, 0o700)
    os.chmod(memory, 0o700)
    return memory


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
        metadata = block_metadata(body)
        if not body or metadata.get("status", "").casefold() in {"superseded", "retired", "rejected"}:
            continue
        if is_expired(metadata):
            continue
        yield {
            "path": relative_name(path, root),
            "line": start + 1,
            "text": body,
            "metadata": metadata,
        }


def block_metadata(text: str) -> dict[str, str]:
    fields: dict[str, str] = {}
    for key, value in re.findall(r"^- \*\*([A-Za-z0-9_-]+)\*\*:\s*(.*?)\s*$", text, re.M):
        fields[key.casefold().replace("-", "_")] = value.strip()
    return fields


def parse_date(value: str) -> dt.date | None:
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        return None
    try:
        return dt.date.fromisoformat(value)
    except ValueError:
        return None


def is_expired(metadata: dict[str, str], today: dt.date | None = None) -> bool:
    expires = parse_date(metadata.get("expires_at", "") or metadata.get("expires", ""))
    return bool(expires and expires < (today or dt.date.today()))


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


def metadata_score(metadata: dict[str, str], today: dt.date) -> float:
    confidence = {"low": 0.0, "medium": 0.2, "high": 0.4}.get(metadata.get("confidence", "").casefold(), 0.0)
    verified = parse_date(metadata.get("verified_at", "") or metadata.get("approved_at", ""))
    freshness = 0.0
    if verified:
        age = max(0, (today - verified).days)
        freshness = math.exp(-age / 90.0) * 0.35
    return confidence + freshness


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
            score += recency_score(item["path"], today) + importance_score(body) + metadata_score(item["metadata"], today)
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
    limits = {f"{name}.md": limit for name, limit in ACTIVE_CHAR_LIMITS.items()}
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


def optional_field(arguments: dict[str, Any], name: str, maximum: int) -> str:
    value = re.sub(r"\s+", " ", str(arguments.get(name, "")).strip())
    if len(value) > maximum or any(ord(character) < 32 for character in value):
        raise MemoryError(f"{name} 最多 {maximum} 个字符")
    return value


def atomic_write(path: Path, content: str) -> None:
    if path.exists() and path.is_symlink():
        raise MemoryError(f"{path.name} 不能是符号链接")
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=f".{path.name}-", suffix=".tmp", dir=path.parent)
    try:
        os.fchmod(fd, 0o600)
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_name, path)
        os.chmod(path, 0o600)
    finally:
        if os.path.exists(temp_name):
            os.unlink(temp_name)


def pending_entries(root: Path) -> tuple[Path, str, list[dict[str, Any]]]:
    pending = memory_root(root) / "memory" / "pending.md"
    if pending.is_symlink():
        raise MemoryError("pending.md 不能是符号链接")
    text = safe_read(pending) if pending.exists() else "# Pending Memory\n"
    matches = list(re.finditer(r"^## (PENDING-\d+):\s*(.*?)\s*$", text, re.M))
    entries = []
    for index, match in enumerate(matches):
        end = matches[index + 1].start() if index + 1 < len(matches) else len(text)
        body = text[match.start() : end].strip()
        entries.append({"id": match.group(1), "title": match.group(2), "body": body, "metadata": block_metadata(body)})
    return pending, text, entries


def active_conflicts(root: Path, target: str, subject: str) -> list[str]:
    root = root.resolve()
    if not subject:
        return []
    path = memory_root(root) / "memory" / ACTIVE_MEMORY_FILES[target]
    if not path.is_file() or path.is_symlink():
        return []
    conflicts = []
    for item in chunks(path, root):
        if item["metadata"].get("subject", "").casefold() == subject.casefold():
            conflicts.append(item["text"].splitlines()[0].lstrip("# ")[:120])
    return conflicts


def active_duplicate(root: Path, target: str, proposal: str) -> dict[str, str] | None:
    path = memory_root(root) / "memory" / ACTIVE_MEMORY_FILES[target]
    if not path.is_file() or path.is_symlink():
        return None
    for item in chunks(path, root):
        metadata = item["metadata"]
        active_value = metadata.get("directive", "") or metadata.get("content", "") or metadata.get("proposal", "")
        if active_value.casefold() == proposal.casefold():
            heading = item["text"].splitlines()[0]
            identifier = re.sub(r"^##\s+", "", heading).split(":", 1)[0].strip()
            return {
                "id": identifier[:120],
                "path": relative_name(path, root),
            }
    return None


def advance_pending_counter(text: str, value: int) -> str:
    marker = f"<!-- ask-buddy:last-pending-id={value} -->"
    pattern = r"<!-- ask-buddy:last-pending-id=\d+ -->"
    if re.search(pattern, text):
        return re.sub(pattern, marker, text, count=1)
    lines = text.splitlines()
    if lines and lines[0].startswith("#"):
        return "\n".join([lines[0], marker, *lines[1:]]).rstrip() + "\n"
    return marker + "\n" + text


def _stage_candidate(root: Path, arguments: dict[str, Any], *, kind: str = "candidate", extra: dict[str, str] | None = None) -> dict[str, Any]:
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
    subject = optional_field(arguments, "subject", 120)
    source = optional_field(arguments, "source", 200) or "assistant-proposal"
    expires_at = optional_field(arguments, "expires_at", 10)
    supersedes = optional_field(arguments, "supersedes", 120)
    if expires_at and not parse_date(expires_at):
        raise MemoryError("expires_at 必须是 YYYY-MM-DD")
    directory = ensure_memory_directory(root)
    pending, existing, entries = pending_entries(root)
    duplicate = next((entry for entry in entries if entry["metadata"].get("proposal", "").casefold() == proposal.casefold()), None)
    if duplicate:
        return {"id": duplicate["id"], "status": "pending", "active": False, "duplicate": True, "path": relative_name(pending, root)}
    duplicate_active = active_duplicate(root, target, proposal)
    if duplicate_active:
        return {**duplicate_active, "status": "active", "active": True, "duplicate": True}
    ids = [int(entry["id"].split("-")[1]) for entry in entries]
    ids.extend(int(value) for value in re.findall(r"<!-- ask-buddy:last-pending-id=(\d+) -->", existing))
    for active_file in allowed_files(root):
        ids.extend(int(value) for value in re.findall(r"^## PENDING-(\d+)", safe_read(active_file), re.M))
    candidate_id = f"PENDING-{max(ids, default=0) + 1:03d}"
    conflicts = active_conflicts(root, target, subject)
    fields = {
        "target": target,
        "proposal": proposal,
        "reason": reason,
        "evidence": evidence,
        "confidence": confidence,
        "source": source,
        "subject": subject,
        "expires_at": expires_at,
        "supersedes": supersedes,
        "created": dt.date.today().isoformat(),
        "review_after": "next-related-task",
    }
    fields.update(extra or {})
    rendered = [f"## {candidate_id}: {kind}"]
    rendered.extend(f"- **{key}**: {value}" for key, value in fields.items() if value)
    existing = advance_pending_counter(existing, int(candidate_id.split("-")[1]))
    atomic_write(pending, existing.rstrip() + "\n\n" + "\n".join(rendered) + "\n")
    return {
        "id": candidate_id,
        "status": "pending",
        "active": False,
        "duplicate": False,
        "potential_conflicts": conflicts,
        "path": relative_name(pending, root),
    }


def stage_memory(root: Path, arguments: dict[str, Any]) -> dict[str, Any]:
    return _stage_candidate(root, arguments)


def learning_stage(root: Path, arguments: dict[str, Any]) -> dict[str, Any]:
    procedure = arguments.get("procedure")
    if not isinstance(procedure, list) or not 1 <= len(procedure) <= 12:
        raise MemoryError("procedure 必须包含 1–12 个步骤")
    steps = [clean_field({"step": item}, "step", 300) for item in procedure]
    outcome = str(arguments.get("outcome", ""))
    if outcome not in {"success", "failure", "correction"}:
        raise MemoryError("outcome 必须是 success、failure 或 correction")
    staged = dict(arguments)
    staged.update({
        "target": "playbook",
        "proposal": clean_field(arguments, "name", 120),
        "reason": f"{outcome}: {clean_field(arguments, 'goal', 500)}",
        "source": "learning-review",
        "subject": optional_field(arguments, "subject", 120) or f"procedure:{optional_field(arguments, 'trigger', 500)[:80]}",
    })
    extra = {
        "trigger": clean_field(arguments, "trigger", 500),
        "goal": clean_field(arguments, "goal", 500),
        "procedure": " | ".join(f"{index}. {step}" for index, step in enumerate(steps, 1)),
        "verification": clean_field(arguments, "verification", 500),
        "fallback": clean_field(arguments, "fallback", 500),
        "outcome": outcome,
    }
    return _stage_candidate(root, staged, kind="procedure", extra=extra)


def list_pending(root: Path, limit: int = 20) -> dict[str, Any]:
    if not 1 <= limit <= 50:
        raise MemoryError("limit 必须为 1–50")
    _, _, entries = pending_entries(root)
    selected = []
    for entry in entries[:limit]:
        metadata = entry["metadata"]
        target = metadata.get("target", "")
        selected.append({
            "id": entry["id"],
            "kind": entry["title"],
            "target": target,
            "proposal": metadata.get("proposal", ""),
            "reason": metadata.get("reason", ""),
            "evidence": metadata.get("evidence", ""),
            "confidence": metadata.get("confidence", ""),
            "source": metadata.get("source", ""),
            "subject": metadata.get("subject", ""),
            "expires_at": metadata.get("expires_at", ""),
            "supersedes": metadata.get("supersedes", ""),
            "trigger": metadata.get("trigger", ""),
            "goal": metadata.get("goal", ""),
            "procedure": metadata.get("procedure", ""),
            "verification": metadata.get("verification", ""),
            "fallback": metadata.get("fallback", ""),
            "outcome": metadata.get("outcome", ""),
            "potential_conflicts": active_conflicts(root, target, metadata.get("subject", "")) if target in {"profile", "memory", "playbook"} else [],
            "active": False,
        })
    return {"count": len(selected), "candidates": selected, "active": False}


def _mark_superseded(text: str, identifier: str) -> str:
    starts = list(re.finditer(r"^##\s+.*$", text, re.M))
    matches = []
    for index, start in enumerate(starts):
        end = starts[index + 1].start() if index + 1 < len(starts) else len(text)
        block = text[start.start() : end]
        if identifier.casefold() in block.casefold():
            matches.append((start.start(), end, block))
    if len(matches) != 1:
        raise MemoryError("supersedes 必须唯一匹配一条有效记忆")
    start, end, block = matches[0]
    if re.search(r"^- \*\*status\*\*:", block, re.M):
        block = re.sub(r"^- \*\*status\*\*:\s*.*$", "- **status**: superseded", block, count=1, flags=re.M)
    else:
        block = block.rstrip() + "\n- **status**: superseded\n"
    return text[:start] + block + text[end:]


def _next_active_id(text: str, target: str) -> str:
    prefix = {"profile": "PREF", "memory": "MEM", "playbook": "PROC"}[target]
    values = [int(value) for value in re.findall(rf"^## {prefix}-(\d+)", text, re.M)]
    return f"{prefix}-{max(values, default=0) + 1:03d}"


def _render_approved(candidate_id: str, active_id: str, target: str, proposal: str, metadata: dict[str, str], supersedes: str) -> str:
    today = dt.date.today().isoformat()
    title = proposal[:120]
    common = {
        "subject": metadata.get("subject", ""),
        "source": metadata.get("source", ""),
        "evidence": metadata.get("evidence", ""),
        "confidence": metadata.get("confidence", ""),
        "candidate": candidate_id,
        "approved_by": "user",
        "approved_at": today,
        "expires_at": metadata.get("expires_at", ""),
        "supersedes": supersedes,
        "status": "active",
    }
    if target == "profile":
        fields = {"directive": proposal, **common}
    elif target == "memory":
        fields = {
            "kind": "fact",
            "content": proposal,
            "observed_at": metadata.get("created", today),
            "verified_at": today,
            **common,
        }
    elif metadata.get("trigger") and metadata.get("procedure"):
        outcome = metadata.get("outcome", "")
        fields = {
            "trigger": metadata.get("trigger", ""),
            "scope": "current project",
            "goal": metadata.get("goal", ""),
            "steps": metadata.get("procedure", ""),
            "verification": metadata.get("verification", ""),
            "fallback": metadata.get("fallback", ""),
            "last_used": "never",
            "successes": "1" if outcome == "success" else "0",
            "failures": "1" if outcome in {"failure", "correction"} else "0",
            "outcome": outcome,
            **common,
        }
    else:
        fields = {"content": proposal, **common}
    rendered = [f"## {active_id}: {title}"]
    rendered.extend(f"- **{key}**: {value}" for key, value in fields.items() if value)
    return "\n".join(rendered)


def decide_pending(
    root: Path,
    candidate_id: str,
    action: str,
    *,
    proposal_override: str = "",
    supersedes_override: str = "",
) -> dict[str, Any]:
    candidate_id = candidate_id.strip().upper()
    if not re.fullmatch(r"PENDING-\d{3,}", candidate_id) or action not in {"approve", "reject"}:
        raise MemoryError("候选 ID 或 action 无效")
    proposal_override = optional_field({"value": proposal_override}, "value", 1500)
    supersedes_override = optional_field({"value": supersedes_override}, "value", 120)
    if action == "reject" and (proposal_override or supersedes_override):
        raise MemoryError("reject 不接受 proposal 或 supersedes")
    pending, text, entries = pending_entries(root)
    entry = next((item for item in entries if item["id"] == candidate_id), None)
    if not entry:
        raise MemoryError("未找到待处理候选")
    metadata = entry["metadata"]
    target = metadata.get("target", "")
    if target not in {"profile", "memory", "playbook"}:
        raise MemoryError("候选 target 无效")
    conflicts = active_conflicts(root, target, metadata.get("subject", ""))
    supersedes = supersedes_override or metadata.get("supersedes", "")
    if action == "approve" and conflicts and not supersedes:
        raise MemoryError("候选与有效记忆冲突；请明确填写 supersedes 后再批准")
    match = re.search(rf"^## {re.escape(candidate_id)}:.*?(?=^## PENDING-|\Z)", text, re.M | re.S)
    if not match:
        raise MemoryError("候选内容损坏")
    if action == "approve":
        active = memory_root(root) / "memory" / ACTIVE_MEMORY_FILES[target]
        if active.is_symlink():
            raise MemoryError(f"{active.name} 不能是符号链接")
        active_text = safe_read(active) if active.exists() else f"# {target.title()}\n"
        if supersedes:
            active_text = _mark_superseded(active_text, supersedes)
        proposal = proposal_override or metadata.get("proposal", entry["title"])
        active_id = _next_active_id(active_text, target)
        approved = _render_approved(candidate_id, active_id, target, proposal, metadata, supersedes)
        updated_active = active_text.rstrip() + "\n\n" + approved + "\n"
        limit = ACTIVE_CHAR_LIMITS[target]
        if len(updated_active) > limit:
            raise MemoryError(f"{active.name} 批准后将超过 {limit} 字符；请先合并或精简现有记忆")
        atomic_write(active, updated_active)
    new_pending = text[: match.start()] + text[match.end() :]
    atomic_write(pending, new_pending.rstrip() + "\n")
    return {
        "id": active_id if action == "approve" else candidate_id,
        "candidate_id": candidate_id,
        "status": "approved" if action == "approve" else "rejected",
        "active": action == "approve",
        "target": target,
    }


TOOLS = [
    {
        "name": "memory_status",
        "description": "查看本项目 Ask Buddy 本地记忆的文件规模、待确认数量和容量警告，不返回待确认内容。",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    {
        "name": "memory_search",
        "description": "在已激活的分层 Markdown 记忆中做本地混合检索。综合相关性、时效、置信度和核实时间，自动排除 pending、过期、备份和 superseded 条目。",
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
                "source": {"type": "string", "maxLength": 200},
                "subject": {"type": "string", "maxLength": 120, "description": "用于发现同主题冲突的稳定键"},
                "expires_at": {"type": "string", "pattern": "^[0-9]{4}-[0-9]{2}-[0-9]{2}$"},
                "supersedes": {"type": "string", "maxLength": 120, "description": "要取代的有效记忆唯一标识"},
            },
            "required": ["target", "proposal", "reason", "evidence", "confidence"],
            "additionalProperties": False,
        },
    },
    {
        "name": "learning_stage",
        "description": "把已验证的成功、失败恢复或用户纠正暂存为结构化 Playbook 候选；不会自动生效。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {"type": "string", "maxLength": 120},
                "trigger": {"type": "string", "maxLength": 500},
                "goal": {"type": "string", "maxLength": 500},
                "procedure": {"type": "array", "items": {"type": "string", "maxLength": 300}, "minItems": 1, "maxItems": 12},
                "verification": {"type": "string", "maxLength": 500},
                "fallback": {"type": "string", "maxLength": 500},
                "evidence": {"type": "string", "maxLength": 1500},
                "outcome": {"type": "string", "enum": ["success", "failure", "correction"]},
                "confidence": {"type": "string", "enum": ["low", "medium", "high"], "default": "medium"},
                "subject": {"type": "string", "maxLength": 120},
                "supersedes": {"type": "string", "maxLength": 120}
            },
            "required": ["name", "trigger", "goal", "procedure", "verification", "fallback", "evidence", "outcome", "confidence"],
            "additionalProperties": False
        },
    },
    {
        "name": "learning_pending",
        "description": "列出等待用户审核的记忆与 Playbook 候选。候选内容始终标记为 inactive。",
        "inputSchema": {"type": "object", "properties": {"limit": {"type": "integer", "minimum": 1, "maximum": 50, "default": 20}}, "additionalProperties": False},
    },
    {
        "name": "learning_decide",
        "description": "仅在用户明确批准或拒绝后处理候选；批准会写入正式 Markdown，并保留来源、置信度与审批时间。",
        "inputSchema": {
            "type": "object",
            "properties": {
                "id": {"type": "string", "pattern": "^PENDING-[0-9]{3,}$"},
                "action": {"type": "string", "enum": ["approve", "reject"]},
                "proposal": {"type": "string", "maxLength": 1500, "description": "仅 approve：按用户修改后的最终内容批准"},
                "supersedes": {"type": "string", "maxLength": 120, "description": "仅 approve：明确要替换的有效记忆唯一标识"}
            },
            "required": ["id", "action"],
            "additionalProperties": False
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
    if name == "learning_stage":
        return learning_stage(root, arguments)
    if name == "learning_pending":
        return list_pending(root, int(arguments.get("limit", 20)))
    if name == "learning_decide":
        return decide_pending(
            root,
            str(arguments.get("id", "")),
            str(arguments.get("action", "")),
            proposal_override=str(arguments.get("proposal", "")),
            supersedes_override=str(arguments.get("supersedes", "")),
        )
    raise MemoryError(f"未知工具：{name}")


def rpc_result(request_id: Any, result: Any) -> dict[str, Any]:
    return {"jsonrpc": "2.0", "id": request_id, "result": result}


def handle(message: dict[str, Any], root: Path) -> dict[str, Any] | None:
    if not isinstance(message, dict):
        return {"jsonrpc": "2.0", "id": None, "error": {"code": -32600, "message": "Invalid Request"}}
    method = message.get("method")
    request_id = message.get("id")
    if request_id is None:
        return None
    if method == "initialize":
        params = message.get("params", {})
        if params is None:
            params = {}
        if not isinstance(params, dict):
            return {"jsonrpc": "2.0", "id": request_id, "error": {"code": -32602, "message": "params 必须是对象"}}
        requested = params.get("protocolVersion", "2025-11-25")
        return rpc_result(request_id, {"protocolVersion": requested, "capabilities": {"tools": {"listChanged": False}}, "serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION}})
    if method == "server/discover":
        return rpc_result(request_id, {
            "resultType": "complete",
            "supportedVersions": ["2026-07-28"],
            "capabilities": {"tools": {}},
            "_meta": {"io.modelcontextprotocol/serverInfo": {"name": SERVER_NAME, "version": SERVER_VERSION}},
            "instructions": "Local Markdown memory with lightweight retrieval and an explicit candidate approval loop. Pending candidates are inert until the user approves them.",
            "ttlMs": 300_000,
            "cacheScope": "private",
        })
    if method == "ping":
        return rpc_result(request_id, {})
    if method == "tools/list":
        return rpc_result(request_id, {"resultType": "complete", "tools": TOOLS, "ttlMs": 300_000, "cacheScope": "private"})
    if method == "tools/call":
        params = message.get("params", {})
        if params is None:
            params = {}
        try:
            if not isinstance(params, dict):
                raise MemoryError("params 必须是对象")
            arguments = params.get("arguments", {})
            if arguments is None:
                arguments = {}
            if not isinstance(arguments, dict):
                raise MemoryError("arguments 必须是对象")
            value = call_tool(str(params.get("name", "")), arguments, root)
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
