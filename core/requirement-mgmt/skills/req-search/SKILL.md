---
name: req-search
description: 在配置的需求管理系统中搜索/查询 issue。Jira 使用 JQL，Linear 使用 GraphQL filter，GitHub 使用 search API。
argument-hint: "<搜索查询，Jira 用 JQL、GitHub 用 search 语法>"
allowed-tools: ["Read", "Bash(bash*)"]
---

# Requirement Search

## Overview

在需求管理系统中搜索 issue。查询语法取决于配置的 provider。

## When to Use

- 查找相关 issue
- 按条件筛选 issue（状态、负责人、标签等）
- 了解项目进度或积压

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `query` | Yes | 搜索查询（语法因 provider 而异） |

| Output | Format |
|--------|--------|
| 搜索结果 | Markdown 表格 |

## Provider-specific Query Syntax

- **Jira**: JQL，如 `project = PROJ AND status = "In Progress"`
- **Linear**: filter 语法，如 `team:ENG state:started`
- **GitHub Issues**: search 语法，如 `is:open label:bug`

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh search "<QUERY>"
```

若 dispatcher 报错"未找到 config.yaml"，引导用户先执行 `/req-setup` 完成配置。

## Common Mistakes

- **未用引号包裹查询** — 含空格的查询必须用引号。
- **使用了错误 provider 的语法** — 查询语法因 provider 而异。
