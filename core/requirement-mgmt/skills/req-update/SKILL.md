---
name: req-update
description: 更新已有 issue 的字段（summary、description、priority 等）。接受 issue ID 和 JSON 文件。
argument-hint: "<Issue ID> <JSON 文件路径>"
allowed-tools: ["Read", "Bash(bash*)"]
---

# Requirement Update

## Overview

更新配置的需求管理 provider 中已有 issue 的字段。通过 JSON 文件传递要更新的字段，仅覆盖指定字段，不影响其他字段。

## When to Use

- 本地 Story 内容变更后同步到 Jira
- 批量更新 issue 的 description/summary
- 修正已发布 issue 的内容

**Not for:** 创建新 issue（使用 `/req-create`）、状态变更（使用 `/req-transition`）。

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `issue_id` | Yes | Issue key（如 `SCRUM-10`） |
| `json_file` | Yes | 包含更新 payload 的 JSON 文件路径 |

## JSON Payload 格式

只需包含要更新的字段。Jira 示例：

```json
{
  "fields": {
    "summary": "更新后的标题",
    "description": "更新后的描述"
  }
}
```

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh update <ISSUE_ID> <JSON_FILE>
```

若 dispatcher 报错"未找到 config.yaml"，引导用户先执行 `/req-setup` 完成配置。

## Common Mistakes

- **传入了 key/id/project 等只读字段** — 更新 payload 不应包含不可变字段。
- **v2/v3 description 格式差异** — Jira API v2 用纯文本，v3 用 ADF 格式。
