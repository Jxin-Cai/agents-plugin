---
name: req-transition
description: 执行 issue 状态转换。需提供目标状态名称（不区分大小写）。建议先用 /req-transitions 确认可用选项。
argument-hint: "<Issue ID> <目标状态名称>"
allowed-tools: ["Read", "Bash(bash*)", "AskUserQuestion", "Skill"]
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

先执行：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh status
```

若返回 `CONFIG_FOUND=false`：
- 用 AskUserQuestion 询问是否立即初始化
- 若用户同意，调用 `/req-setup` 完成配置
- setup 完成后，继续当前 transition 操作
- 若用户拒绝，则停止并说明当前项目缺少 `.requirement-mgmt/config.yaml`


## Common Mistakes

- **状态名称拼写错误** — 先执行 `/req-transitions` 确认准确名称。
- **状态不可达** — 某些工作流不允许跨越中间状态。
