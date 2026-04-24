---
name: req-setup
description: 首次使用引导——选择需求管理软件（Jira/Linear/GitHub Issues 等），配置连接信息，并持久化到项目空间。当项目中不存在 .requirement-mgmt/config.yaml 时自动触发。
argument-hint: "[provider 名称，如 jira、github-issues]"
allowed-tools: ["Read", "Write", "Bash(bash*)", "AskUserQuestion"]
---

# Requirement Management Setup

## Overview

引导用户初始化需求管理配置。配置持久化到当前项目的 `.requirement-mgmt/config.yaml`，后续所有需求管理操作自动复用。

统一使用以下辅助脚本：

```bash
REQMGMT_HELPER="core/requirement-mgmt/skills/_lib/setup-helper.sh"
REQMGMT_DISPATCHER="core/requirement-mgmt/skills/_lib/dispatcher.sh"
```

## Implementation

### Step 1: 检测现有配置

先执行：

```bash
bash "$REQMGMT_DISPATCHER" status
```

- 若 `CONFIG_FOUND=true`：再执行

```bash
bash "$REQMGMT_HELPER" summary
```

读取当前 provider、项目根、连接摘要（敏感字段已掩码），然后用 AskUserQuestion 询问：
- **保留当前配置（推荐）**
- **重新配置**

若用户保留，直接结束。

### Step 2: 选择 provider

若 `$ARGUMENTS` 已明确给出 provider，则优先使用；否则先执行：

```bash
bash "$REQMGMT_DISPATCHER" setup
```

从 `name|display_name` 列表生成 AskUserQuestion 选项，让用户选择 provider。

### Step 3: 读取 provider schema

执行：

```bash
bash "$REQMGMT_HELPER" provider-schema <provider>
```

该命令会返回标准化 JSON，包含：
- `connection_fields`
- `options`
- `operations`

后续提问以这个 schema 为准。

### Step 4: 采集连接信息

#### Jira

必收集：
- `base_url`
- `auth_mode`（`pat` / `idtoken`）

提问规则：
- `base_url`：要求用户输入 Jira host，例如 `https://jira.example.com`
- `auth_mode=pat`：要求用户输入 PAT，写入 `connection.token`
- `auth_mode=idtoken`：
  1. 先让用户提供或确认现有登录命令 `login_command`
  2. 明确告知该命令应打开浏览器登录并在 stdout 输出 idtoken
  3. 经用户确认后执行该命令
  4. 取 stdout 作为 `connection.token`
  5. 同时保存 `connection.login_command`

可选项：
- `ssl_verify`
- `api_version`

#### GitHub Issues

必收集：
- `repo`（必须保存，格式 `owner/repo`）
- `auth_mode`（`gh_cli` / `pat`）

提问规则：
- `repo`：要求用户输入默认仓库
- `auth_mode=pat`：要求输入 PAT，写入 `connection.token`
- `auth_mode=gh_cli`：先执行

```bash
gh auth status
```

  - 若已登录：继续
  - 若未登录：提示用户先执行 `! gh auth login`，登录完成后再继续 setup

### Step 5: 写入配置

先确定目标配置路径：

```bash
bash "$REQMGMT_HELPER" config-path
```

然后把采集到的 `connection` / `options` 组织成 JSON 字符串，执行：

```bash
bash "$REQMGMT_HELPER" write-config <provider> '<connection_json>' '<options_json>'
```

期望写出的 YAML 形态：

```yaml
provider: jira
connection:
  base_url: https://jira.example.com
  auth_mode: idtoken
  token: <runtime token>
  login_command: <existing command>
options:
  ssl_verify: true
  api_version: "2"
```

```yaml
provider: github-issues
connection:
  repo: owner/repo
  auth_mode: gh_cli
options: {}
```

### Step 6: 确保忽略本地配置

执行：

```bash
bash "$REQMGMT_HELPER" ensure-gitignore
```

若项目根没有 `.gitignore`，允许创建；若已有但缺少 `.requirement-mgmt/`，则自动追加。

### Step 7: 展示结果并可选验证

再次执行：

```bash
bash "$REQMGMT_HELPER" summary
```

向用户展示掩码后的配置摘要，并询问是否立即做一次验证。

- Jira：若用户提供测试 issue key，则执行

```bash
bash "$REQMGMT_DISPATCHER" fetch <ISSUE_ID>
```

- GitHub：若用户愿意验证，可执行

```bash
bash "$REQMGMT_DISPATCHER" search "is:open"
```

或针对具体 issue 执行 `fetch`。

## Notes

- 所有敏感字段只展示掩码，禁止回显完整 token
- `idtoken` 路径只复用用户现有登录命令，不在本技能内新做 OAuth 回调服务
- 若已有配置，仅在用户明确要求时重配
- 配置写入当前项目的 `.requirement-mgmt/`，不是全局目录
