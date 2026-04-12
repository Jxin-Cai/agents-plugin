---
name: req-transition
description: 执行 issue 状态转换。需提供目标状态名称（不区分大小写）。建议先用 /req-transitions 确认可用选项。
argument-hint: "<Issue ID> <目标状态名称>"
allowed-tools: ["Read", "Bash(bash*)"]
---

# Requirement Transition

## Overview

将 issue 转换到指定状态。自动按名称匹配（不区分大小写）。

## When to Use

- MR 创建后将 issue 移至 "In Review"
- 代码合并后将 issue 移至 "Done"
- 构建失败后将 issue 回退

## Quick Reference

| Input | Required | Description |
|-------|----------|-------------|
| `issue_id` | Yes | Issue key |
| `status_name` | Yes | 目标状态名称（不区分大小写） |

## Implementation

```bash
# 建议先查看可用转换
bash core/requirement-mgmt/skills/_lib/dispatcher.sh transitions <ISSUE_ID>

# 执行转换
bash core/requirement-mgmt/skills/_lib/dispatcher.sh transition <ISSUE_ID> "<STATUS_NAME>"
```

若 dispatcher 报错"未找到 config.yaml"，引导用户先执行 `/req-setup` 完成配置。

## Common Mistakes

- **状态名称拼写错误** — 先执行 `/req-transitions` 确认准确名称。
- **状态不可达** — 某些工作流不允许跨越中间状态。
