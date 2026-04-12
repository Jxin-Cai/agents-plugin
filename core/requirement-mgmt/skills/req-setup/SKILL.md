---
name: req-setup
description: 首次使用引导——选择需求管理软件（Jira/Linear/GitHub Issues 等），配置连接信息，并持久化到项目空间。当项目中不存在 .requirement-mgmt/config.yaml 时自动触发。
argument-hint: "[provider 名称，如 jira、github-issues]"
allowed-tools: ["Read", "Write", "Bash(bash*)", "AskUserQuestion"]
---

# Requirement Management Setup

## Overview

引导用户选择和配置需求管理软件。配置持久化到项目空间的 `.requirement-mgmt/config.yaml`，后续所有需求管理操作自动基于此配置。

## When to Use

- 项目首次使用需求管理集成
- 需要更换需求管理软件
- 需要更新连接配置

## Implementation

### Step 1: 检测现有配置

从当前目录向上查找 `.requirement-mgmt/config.yaml`。

- **若存在**：展示当前配置（provider 名称、连接信息摘要），用 AskUserQuestion 询问是否重新配置。若用户选择保留，直接结束。
- **若不存在**：继续下一步。

### Step 2: 扫描可用 Providers

运行 dispatcher 的 setup 模式获取可用 provider 列表：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh setup
```

输出格式为 `name|display_name`，每行一个。

### Step 3: Provider 选择

用 AskUserQuestion 让用户选择：

> 你的团队使用哪种需求管理软件？

选项从 Step 2 的输出动态生成。

### Step 4: 连接配置

读取选中 provider 的 `provider.yaml`（位于 `core/requirement-mgmt/skills/_providers/<provider>/provider.yaml`），遍历 `connection_fields`：

- 对每个 `required: true` 的字段，引导用户输入真实配置值
- 对每个 `required: false` 的字段，展示默认值并询问是否需要填写
- 对 `secret: true` 的字段，明确告知这是授权信息/Token，将保存在项目空间的 `.requirement-mgmt/config.yaml` 中，仅供当前项目长期复用
- 若用户不希望直接保存，可保留旧环境变量模式作为兼容回退，但默认推荐保存到项目空间

### Step 5: 持久化

在项目根目录创建 `.requirement-mgmt/config.yaml`：

```yaml
provider: <selected_provider>
connection:
  <key>: <real_value>
  ...
options:
  ...
```

要求：
- `.requirement-mgmt/` 默认加入 `.gitignore`
- 这是项目级本地配置，用于第一次授权后长期复用
- 展示配置摘要时，对敏感字段只展示掩码，不回显完整 token

### Step 6: 验证（可选）

如果用户愿意提供一个测试 issue ID，运行一次 fetch 验证连接：

```bash
bash core/requirement-mgmt/skills/_lib/dispatcher.sh fetch <TEST_ISSUE_ID>
```

### Step 7: 确认

展示最终配置摘要，并提示后续可使用的技能：
- `/req-fetch <ISSUE_ID>` — 读取 issue
- `/req-comment <ISSUE_ID> <TEXT>` — 添加评论
- `/req-search <QUERY>` — 搜索 issue

## Notes

- 首次使用时必须主动引导用户输入 provider、URL、默认仓库、Token 等关键信息
- 输入后的配置保存在项目空间，后续同项目下直接复用，不再重复询问
- 若检测到已有配置，仅在用户明确要求时才重新配置
