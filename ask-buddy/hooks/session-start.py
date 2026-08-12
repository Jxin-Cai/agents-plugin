#!/usr/bin/env python3
"""Inject only safe identity, profile, checkpoint, and memory health context."""

from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

from state_context import UnsafeState, active_profile, project_root, safe_directory, safe_text


PLUGIN_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(PLUGIN_ROOT / "servers"))

import memory_server  # noqa: E402


def emit(title: str, content: str) -> None:
    if content:
        print(f"## {title}\n")
        print(content)
        print()


def main() -> int:
    identity = PLUGIN_ROOT / "skills" / "qa-guide" / "references" / "ask-buddy-agent.md"
    try:
        print(identity.read_text(encoding="utf-8").rstrip())
    except (OSError, UnicodeError):
        print("# Ask Buddy\n\n本地优先、只读、记忆可控的个人助理。")
    print("\n---\n")

    try:
        root = project_root()
        state = safe_directory(root, ".ask-buddy")
        memory = safe_directory(root, ".ask-buddy/memory")
    except UnsafeState as exc:
        print(f"## 记忆安全状态\n\n已禁用项目记忆：{exc}")
        return 0

    if not state.exists():
        print("## 初始化状态\n\n尚未建立用户档案。先完成当前请求，再在自然停顿处提供一次轻量初始化邀请。")
    else:
        try:
            profile = active_profile(safe_text(root, memory / "profile.md", 3000))
            checkpoint = safe_text(root, state / "session-context.md", 3000)
        except (OSError, UnicodeError, UnsafeState) as exc:
            print(f"## 记忆安全状态\n\n已跳过不安全或损坏的上下文：{exc}")
            profile = ""
            checkpoint = ""
        if profile:
            emit("User model snapshot", profile)
        else:
            print("## 初始化状态\n\n尚未建立用户档案。先完成当前请求，再在自然停顿处提供一次轻量初始化邀请。\n")
        emit("Current checkpoint", checkpoint)

        try:
            health = memory_server.status(root)
            print("## Memory retrieval\n")
            print(
                f"- {health['active_files']} 个本地 Markdown 记忆文件可通过 `memory_search` / `memory_get` 按需检索；启动时不注入完整长期记忆。"
            )
            if health["pending_count"]:
                print(f"- {health['pending_count']} 条候选等待用户审核；候选尚未生效。")
            for warning in health["warnings"][:3]:
                print(f"- 容量提示：{warning}")
            print()
        except (OSError, ValueError, memory_server.MemoryError) as exc:
            print(f"## Memory retrieval\n\n- 记忆健康检查不可用：{exc}\n")

    if shutil.which("npx"):
        print("- 搜索：OneSearch 已配置；仅在需要实时核实时调用")
    else:
        print("- 搜索：npx 不可用；联网能力将优雅降级")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
