---
name: req-fetch
description: 从配置的需求管理系统（Jira/Linear/GitHub Issues 等）获取 issue 详情。首次使用时引导配置。当用户提及 ticket/issue ID 时触发。
argument-hint: "<Issue ID，如 PROJ-123、#42>"
allowed-tools: ["Read", "Bash(bash*)", "AskUserQuestion", "Skill"]
---

# Requirement Fetch

## Overview

从配置的需求管理 provider 获取 issue 详情，输出结构化 markdown。使用 `.requirement-mgmt/config.yaml` 确定目标系统。

## When to Use

- 开始处理某个 ticket/issue
- 查看 issue 详情或验收标准
- 查看关联 issue

**Not for:** 更新 issue（使用 `/req-comment`、`/req-transition`）。

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `issue_id` | Yes | Issue key（如 `PROJ-1234`、`ENG-123`、`#42`） |

| Output | Location |
|--------|----------|
| Issue 摘要 | stdout（可重定向到文件） |

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh fetch <ISSUE_ID>
```

先执行：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh status
```

若返回 `CONFIG_FOUND=false`：
- 用 AskUserQuestion 询问是否立即初始化
- 若用户同意，调用 `/req-setup` 完成配置
- setup 完成后，继续当前 fetch 操作
- 若用户拒绝，则停止并说明当前项目缺少 `.requirement-mgmt/config.yaml`


## Common Mistakes

- **未配置** — 必须先执行 `/req-setup`，或先完成 `.requirement-mgmt/config.yaml` 配置。
- **Issue key 格式错误** — 每个 provider 有不同的 key 格式。Jira: `PROJECT-NUMBER`，Linear: `TEAM-NUMBER`，GitHub: `#NUMBER`。
