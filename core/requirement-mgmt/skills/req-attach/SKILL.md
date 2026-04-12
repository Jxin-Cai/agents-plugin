---
name: req-attach
description: 向 issue 上传文件附件。适用于测试报告、设计文档、构建产物等。
argument-hint: "<Issue ID> <文件路径>"
allowed-tools: ["Read", "Bash(bash*)"]
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

若 dispatcher 报错"未找到 config.yaml"，引导用户先执行 `/req-setup` 完成配置。

## Common Mistakes

- **文件不存在** — 脚本会检查并报错。
- **文件过大** — 注意 provider 的附件大小限制（Jira 默认 10MB）。
