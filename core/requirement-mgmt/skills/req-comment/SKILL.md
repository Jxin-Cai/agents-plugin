---
name: req-comment
description: 向配置的需求管理系统中的 issue 添加评论。用于记录构建结果、MR 链接、部署状态等里程碑信息。
argument-hint: "<Issue ID> <评论内容>"
allowed-tools: ["Read", "Bash(bash*)"]
---

# Requirement Comment

## Overview

向 issue 添加评论。适用于里程碑事件（构建完成、MR 创建、部署验证等）。

## When to Use

- MR 创建后添加链接
- 构建完成后记录结果
- 部署验证后添加证据

**Not for:** 读取 issue（使用 `/req-fetch`）。

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `issue_id` | Yes | Issue key |
| `comment` | Yes | 评论文本 |

## Implementation

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh comment <ISSUE_ID> "<COMMENT_TEXT>"
```

若 dispatcher 报错"未找到 config.yaml"，引导用户先执行 `/req-setup` 完成配置。

### 常见里程碑评论模板

- **构建完成**: `Build passed. Target: {target}/{product}. Binary: {path}`
- **部署验证**: `Deployed and verified. Process running confirmed.`
- **MR 创建**: `MR created: {url}. Reviewers: {names}`

## Common Mistakes

- **评论过长** — 大段日志应改用 `/req-attach` 上传附件。
