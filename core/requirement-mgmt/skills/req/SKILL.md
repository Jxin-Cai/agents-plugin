---
name: req
description: 需求管理工作台——识别操作意图并路由到对应子技能（查询/评论/搜索/状态变更/附件/配置）
argument-hint: "<操作指令，如 'PROJ-123'、'search 关键词'、'setup'>"
allowed-tools: ["Read", "Bash(bash*)", "AskUserQuestion", "Skill"]
---

# 需求管理工作台

统一入口编排技能，解析用户意图并路由到对应的需求管理子技能。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 定位脚本根目录

本技能集合位于 `core/requirement-mgmt/skills/`。所有 dispatcher 调用使用以下路径：

```
REQMGMT_SKILLS="core/requirement-mgmt/skills"
```

---

## Step 1: 配置检测

运行以下命令检测配置状态：

```bash
bash "${REQMGMT_SKILLS}/_lib/dispatcher.sh" status
```

若用户操作不是 `setup` / `配置` / `初始化`，且检测结果为 `CONFIG_FOUND=false`，必须主动进入初始化引导，而不是让用户自己再跑一次命令。

使用 `AskUserQuestion` 提供选项：
- **立即配置（推荐）** — 调用 `/req-setup`
- **暂不配置** — 结束当前操作并说明依赖 `.requirement-mgmt/config.yaml`

如果用户选择立即配置：
1. 调用 `/req-setup`
2. setup 完成后，继续处理当前 `$ARGUMENTS`
3. 不要丢失用户原始意图

---

## Step 2: 意图识别与路由

从 `$ARGUMENTS` 中识别用户意图，按以下规则路由：

| 匹配模式 | 目标子技能 | 说明 |
|----------|-----------|------|
| `setup` / `配置` / `初始化` | `/req-setup` | 配置需求管理系统连接 |
| 纯 issue ID（如 `PROJ-123`、`#42`、`ENG-456`） | `/req-fetch $ARGUMENTS` | 获取 issue 详情 |
| `search` / `搜索` / `查询` + 关键词 | `/req-search <query>` | 搜索 issue |
| `comment` / `评论` + issue ID + 内容 | `/req-comment <id> <text>` | 添加评论 |
| `transitions` / `状态列表` / `可用状态` + issue ID | `/req-transitions <id>` | 列出可用状态转换 |
| `transition` / `状态变更` + issue ID + 目标状态 | `/req-transition <id> <status>` | 执行状态变更 |
| `attach` / `附件` / `上传` + issue ID + 文件路径 | `/req-attach <id> <file>` | 上传附件 |
| `create` / `创建 issue` + JSON 文件路径 | `/req-create <json_file>` | 创建 issue |
| `update` / `更新 issue` + issue ID + JSON 文件路径 | `/req-update <id> <json_file>` | 更新 issue |

---

## Step 3: 模糊意图处理

若 `$ARGUMENTS` 为空或无法匹配上述任一模式，使用 `AskUserQuestion` 展示操作菜单：

> 你想执行什么操作？

选项：
- **查看 issue 详情** — 获取指定 issue 的完整信息（req-fetch）
- **搜索 issue** — 按条件查询 issue 列表（req-search）
- **添加评论** — 向 issue 添加评论（req-comment）
- **查看可用状态转换** — 列出 issue 当前可流转的状态（req-transitions）
- **执行状态变更** — 将 issue 转换到目标状态（req-transition）
- **上传附件** — 向 issue 上传文件（req-attach）
- **创建 issue** — 通过 JSON 文件创建新 issue（req-create）
- **更新 issue** — 通过 JSON 文件更新已有 issue（req-update）
- **配置需求管理系统** — 首次使用或更换系统时执行（req-setup）

用户选择后，使用 `AskUserQuestion` 追问缺失的必要参数（如 issue ID、搜索关键词等），然后调用对应子技能。

---

## Step 4: 结果展示

子技能执行完成后：
1. 展示操作结果
2. 使用 `AskUserQuestion` 询问后续操作：
   - **继续其他操作** — 回到 Step 2
   - **结束** — 退出需求管理工作台

---

<IMPORTANT>
- 始终使用中文与用户沟通
- 非 setup 操作前必须确认配置存在，否则引导 setup
- 每次操作后等待用户确认，不要自动连续执行多个操作
- 对敏感信息（token、密码）仅展示掩码，不回显完整值
</IMPORTANT>
