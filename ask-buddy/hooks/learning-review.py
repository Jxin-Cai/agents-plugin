#!/usr/bin/env python3
"""Lightweight Stop hook that stages only explicit user learning signals."""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path


PLUGIN_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PLUGIN_ROOT / "servers"))

import memory_server  # noqa: E402


MAX_TAIL_BYTES = 256_000
SIGNAL = re.compile(
    r"(?:"
    r"(?:请|帮我)?记住(?:[：:,，\s]|$)|"
    r"(?:以后|下次|今后)(?:请|都|要|务必|别|不要)|不要再|别再|"
    r"我(?:更)?喜欢(?:你|回答|答案|先|用|按|看)|我不喜欢(?:你|回答|答案|用|按)|"
    r"remember(?:\s+that|\s+to|[\s:，,]|$)|from now on|"
    r"next time(?:\s+please|\s+do|\s+don't|[\s:,]|$)|I prefer(?:\s+you|\s+answers?|\s+responses?)|don't do that again"
    r")",
    re.I,
)
SENSITIVE = re.compile(
    r"(?i)(?:"
    r"\b(?:api[_ -]?key|app[_ -]?secret|access[_ -]?token|refresh[_ -]?token|password|private key|"
    r"ssn|social security|passport(?: number)?|credit card|bank account|medical record|diagnosis|phone number|home address)\b|"
    r"密码|密钥|令牌|身份证(?:号)?|护照(?:号)?|银行卡(?:号)?|信用卡(?:号)?|社保(?:号)?|病历|诊断结果|手机号|家庭住址"
    r")"
)


def content_text(content) -> str:
    if isinstance(content, str):
        return content
    if not isinstance(content, list):
        return ""
    return "\n".join(
        str(block.get("text", ""))
        for block in content
        if isinstance(block, dict) and block.get("type") == "text"
    )


def latest_user_message(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        return ""
    size = path.stat().st_size
    with path.open("rb") as handle:
        handle.seek(max(0, size - MAX_TAIL_BYTES))
        raw = handle.read(MAX_TAIL_BYTES)
    messages = []
    for line in raw.decode("utf-8", errors="ignore").splitlines():
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(record, dict):
            continue
        message = record.get("message") if isinstance(record.get("message"), dict) else record
        role = str(message.get("role") or record.get("type") or "").casefold()
        if role == "user":
            text = re.sub(r"\s+", " ", content_text(message.get("content"))).strip()
            if text:
                messages.append(text)
    return messages[-1][:1500] if messages else ""


def extract_directive(message: str, match: re.Match[str]) -> str:
    """Keep one explicit directive clause instead of the full user turn."""
    fragment = message[match.start() :]
    fragment = re.split(r"[。！？!?;；\n]", fragment, maxsplit=1)[0]
    fragment = re.split(r"(?:，|,)(?:另外|同时|顺便|然后|以及)?(?:请|帮我)", fragment, maxsplit=1)[0]
    return re.sub(r"\s+", " ", fragment).strip()[:300]


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, TypeError):
        return 0
    transcript = str(payload.get("transcript_path") or "").strip()
    session_id = str(payload.get("session_id") or payload.get("conversation_id") or "unknown")[:120]
    if not transcript:
        return 0
    message = latest_user_message(Path(transcript).expanduser())
    match = SIGNAL.search(message) if message else None
    if not match or SENSITIVE.search(message):
        return 0
    directive = extract_directive(message, match)
    if not directive:
        return 0
    root = Path(str(payload.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd())).resolve()
    if not root.is_dir():
        return 0
    # A transcript tail cannot establish a reusable, verified procedure. Keep
    # explicit interaction directives in profile; structured playbooks are
    # created by learning_stage with steps and observable verification.
    target = "profile"
    try:
        result = memory_server.stage_memory(root, {
            "target": target,
            "proposal": directive,
            "reason": "用户在当前轮给出了明确、可复用的偏好或行为纠正。",
            "evidence": f"explicit-user-session:{session_id}",
            "confidence": "high" if re.search(r"请记住|记住|remember|不要再|别再|don't do that again", directive, re.I) else "medium",
            "source": "stop-hook-explicit-user",
        })
    except (OSError, ValueError, memory_server.MemoryError):
        return 0
    if not result.get("duplicate"):
        print(json.dumps({"systemMessage": f"Ask Buddy 已暂存学习候选 {result['id']}，需用户批准后才会生效。"}, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
