---
name: req-attach
description: 向 issue 上传文件附件。适用于测试报告、设计文档、构建产物等。
argument-hint: "<Issue ID> <文件路径>"
allowed-tools: ["Read", "Bash(bash*)", "AskUserQuestion", "Skill"]
---

# Requirement Attach

## Overview

向 issue 上传文件附件。

## When to Use

- 上传测试报告
- 附加设计文档
- 上传构建日志（替代超长评论）

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `issue_id` | Yes | Issue key |
| `file_path` | Yes | 本地文件路径 |

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh attach <ISSUE_ID> <FILE_PATH>
```

先执行：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh status
```

若返回 `CONFIG_FOUND=false`：
- 用 AskUserQuestion 询问是否立即初始化
- 若用户同意，调用 `/req-setup` 完成配置
- setup 完成后，继续当前 attach 操作
- 若用户拒绝，则停止并说明当前项目缺少 `.requirement-mgmt/config.yaml`


## Common Mistakes

- **文件不存在** — 脚本会检查并报错。
- **文件过大** — 注意 provider 的附件大小限制（Jira 默认 10MB）。
