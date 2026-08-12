"""Safe, bounded readers shared by Ask Buddy context hooks."""

from __future__ import annotations

import os
import re
import datetime as dt
from pathlib import Path


MAX_CONTEXT_FILE_BYTES = 64_000


class UnsafeState(ValueError):
    """Raised when project memory cannot be read without following links."""


def project_root() -> Path:
    configured = os.environ.get("CLAUDE_PROJECT_DIR", "").strip()
    if not configured or configured.startswith("${"):
        configured = os.getcwd()
    root = Path(configured).expanduser().resolve()
    if not root.is_dir():
        raise UnsafeState("当前项目目录不存在")
    return root


def safe_directory(root: Path, relative: str) -> Path:
    path = root / relative
    if path.is_symlink():
        raise UnsafeState(f"{relative} 不能是符号链接")
    resolved = path.resolve(strict=False)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise UnsafeState(f"{relative} 必须位于当前项目内") from exc
    if path.exists() and not path.is_dir():
        raise UnsafeState(f"{relative} 必须是目录")
    return path


def safe_text(root: Path, path: Path, limit: int) -> str:
    if path.is_symlink() or not path.is_file():
        return ""
    resolved = path.resolve(strict=True)
    try:
        resolved.relative_to(root)
    except ValueError as exc:
        raise UnsafeState(f"{path.name} 必须位于当前项目内") from exc
    if path.stat().st_size > MAX_CONTEXT_FILE_BYTES:
        raise UnsafeState(f"{path.name} 超过安全读取上限")
    content = path.read_text(encoding="utf-8", errors="strict").strip()
    if len(content) > limit:
        return content[:limit] + "\n[bounded snapshot truncated; use memory_search for details]"
    return content


def active_profile(text: str) -> str:
    """Remove superseded profile history from the startup snapshot."""
    text = re.split(r"^##\s+Superseded\s*$", text, maxsplit=1, flags=re.M | re.I)[0]
    sections = re.split(r"(?=^##\s+)", text, flags=re.M)
    active = []
    for section in sections:
        if re.search(r"^- \*\*status\*\*:\s*(superseded|retired|rejected)\s*$", section, re.M | re.I):
            continue
        expiry = re.search(r"^- \*\*expires(?:_at)?\*\*:\s*(\d{4}-\d{2}-\d{2})\s*$", section, re.M | re.I)
        if expiry:
            try:
                if dt.date.fromisoformat(expiry.group(1)) < dt.date.today():
                    continue
            except ValueError:
                continue
        active.append(section)
    return "".join(active).strip()
