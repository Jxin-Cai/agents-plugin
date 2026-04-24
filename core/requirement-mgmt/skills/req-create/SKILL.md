---
name: req-create
description: 在配置的需求管理系统中创建 issue。接受 JSON 文件作为 payload，返回新建 issue 的 key。
argument-hint: "<JSON 文件路径>"
allowed-tools: ["Read", "Bash(bash*)", "AskUserQuestion", "Skill"]
---

# Requirement Create

## Overview

在配置的需求管理 provider 中创建一个新 issue。通过 JSON 文件传递完整的 issue payload，支持任意字段（summary、description、issuetype、parent、priority 等）。

## When to Use

- 将本地产物（PRD、Story）发布到 Jira/Linear 等系统
- 批量创建 Epic + Story 层级结构
- 自动化需求录入

**Not for:** 更新已有 issue（使用 `/req-update`）。

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `json_file` | Yes | 包含 issue 创建 payload 的 JSON 文件路径 |

| Output | Format |
|--------|--------|
| 新建 issue 的 key | 纯文本，如 `SCRUM-10` |

## JSON Payload 格式

JSON 文件内容须符合目标 provider 的 API 格式。Jira 示例：

```json
{
  "fields": {
    "project": { "key": "SCRUM" },
    "summary": "Epic 标题",
    "issuetype": { "name": "Epic" },
    "description": "纯文本描述（API v2）"
  }
}
```

带 parent 的 Story 示例：

```json
{
  "fields": {
    "project": { "key": "SCRUM" },
    "summary": "Story 标题",
    "issuetype": { "name": "故事" },
    "parent": { "key": "SCRUM-10" },
    "description": "作为用户，我想要……以便……"
  }
}
```

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh create <JSON_FILE>
```

先执行：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh status
```

若返回 `CONFIG_FOUND=false`：
- 用 AskUserQuestion 询问是否立即初始化
- 若用户同意，调用 `/req-setup` 完成配置
- setup 完成后，继续当前 create 操作
- 若用户拒绝，则停止并说明当前项目缺少 `.requirement-mgmt/config.yaml`


## Common Mistakes

- **JSON 格式错误** — 确保 JSON 文件语法正确，可先用 `python3 -m json.tool` 校验。
- **issuetype 名称本地化** — Jira Cloud 的 issuetype 名称可能是本地化的（如"故事"而非"Story"），需与实例匹配。
- **parent 字段** — 创建 Story 时通过 `parent.key` 关联 Epic，Epic 须已存在。
