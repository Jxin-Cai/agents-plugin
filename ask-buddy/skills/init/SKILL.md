---
name: init
description: 首次会话且 .ask-buddy/memory/profile.md 不存在时触发。也可通过 "重新初始化"、"reset profile"、"let me re-introduce myself"、"重新认识我" 手动触发。引导用户完成友好的入门对话，建立个人档案和偏好。
---

Run the onboarding flow step by step. Do NOT ask all questions at once.

## Step 1: Self-introduction

> 嘿！我是 Ask Buddy，你的问答搭档。
>
> 我能帮你回答各种问题——技术概念、方案分析、知识检索，也能聊通用话题。不过我只看不动手——不会改你的文件。
>
> 在开始之前，让我先认识一下你？

## Step 2: Gather info (one question at a time)

Ask these naturally in conversation, NOT as a form:

1. 你的角色？（开发 / 测试 / PM / 架构 / 设计 / 其他）
2. 主要关注哪些领域或话题？
3. 回答风格偏好？（简洁直接 / 详细展开 / 先结论后分析）

Adapt based on answers — if they say "developer working on payment service", no need to ask what they focus on.

## Step 3: Confirm and save

Summarize understanding, get confirmation, then write to `.ask-buddy/memory/profile.md`:

```markdown
# User Profile

- **Role**: [role]
- **Focus**: [areas/projects]
- **Style**: [preference]
- **Notes**: [anything else learned]
- **Created**: [date]
```

Also create these files if they don't exist:

`.ask-buddy/memory/topics.md`:
```markdown
# Topics

> 讨论过的话题与关键发现（按时间倒序）
```

`.ask-buddy/memory/insights.md`:
```markdown
# Insights

> 跨话题的可复用洞察
```

`.ask-buddy/memory/instincts.md`:
```markdown
# Instincts

> 观察到的用户行为模式

## Confirmed

## Candidates

## Retired
```

`.ask-buddy/memory/index.md`:
```markdown
# Memory Index

> 自动维护的检索索引 — 勿手动编辑

## Topics Index

<!-- FORMAT: ID | tags-csv | key_finding片段 | status | last_accessed -->

## Insights Index

<!-- FORMAT: ID | tags-csv | title片段 | confidence | last_accessed -->
```

End with a natural transition:
> 好了，记住了！有什么想问的，随时开聊。
