---
name: req-transitions
description: 列出 issue 当前可用的状态转换选项。在执行状态变更前先调用此操作确认可用转换。
argument-hint: "<Issue ID>"
allowed-tools: ["Read", "Bash(bash*)", "AskUserQuestion", "Skill"]
---

# Requirement Transitions

## Overview

查询 issue 当前可用的状态转换列表。执行 `/req-transition` 前应先调用此技能。

## When to Use

- 需要变更 issue 状态前查看可用选项
- 不确定目标状态名称时

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `issue_id` | Yes | Issue key |

| Output | Format |
|--------|--------|
| 转换列表 | `ID: Name` 每行一个 |

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh transitions <ISSUE_ID>
```

先执行：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh status
```

若返回 `CONFIG_FOUND=false`：
- 用 AskUserQuestion 询问是否立即初始化
- 若用户同意，调用 `/req-setup` 完成配置
- setup 完成后，继续当前 transitions 操作
- 若用户拒绝，则停止并说明当前项目缺少 `.requirement-mgmt/config.yaml`


## Common Mistakes

- **跳过此步直接 transition** — 不同 issue 状态下可用的转换不同，必须先确认。
