---
name: req-publish
description: 将本地 Story 清单一键发布为 Jira Issue（Epic + Story 层级），自动创建映射关系
argument-hint: "<需求目录路径或 slug>"
allowed-tools: ["Read", "Bash(bash*)", "Write", "AskUserQuestion", "Skill"]
---

# 需求发布到 Jira

将 story-decompose 产出的 Story 清单解析为结构化数据，批量创建 Jira Issue（Epic + Story），并记录本地 ↔ Jira 的映射关系。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

使用 Read 工具加载以下引用文件，严格遵守其中规则：

- `references/publish-principles.md` — 发布字段映射、优先级映射、幂等性规则、jira-sync.yaml 格式

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 发布前必须检查 `quality_gate.status`、`slice_status`、`uat_status`
- ✅ `uat_status: waived` 时必须记录豁免原因
- ✅ UAT 验收包存在时，询问是否作为附件上传到首个 Epic
- ✅ 发布前必须展示预览，用 `AskUserQuestion` 让用户确认
- ✅ 先创建 Epic、再创建 Story（Story 依赖 Epic key）
- ✅ 每次发布后写入 `meta/jira-sync.yaml` 记录映射
- ✅ 已发布的 issue 不重复创建（幂等性）
- ✅ 创建 Epic/Story 必须调用 `/req-create`，上传附件必须调用 `/req-attach`
- ✅ 首次缺配置时必须通过 `/req` 或 `/req-setup` 初始化并保存项目级 `.requirement-mgmt/config.yaml`
- 🚫 不自动做状态流转
- 🚫 不直接 `curl` Jira REST，不直接调用 `core/requirement-mgmt/skills/_providers/*/api.sh`
- ⏸️ 发布前、发布后都要停下等用户确认

---

## 前置条件

1. 需求平台配置必须可用。发布前先通过 `/req` 的配置检测链路确认；若当前项目还没有 `.requirement-mgmt/config.yaml`，调用 `/req` 或 `/req-setup` 完成初始化，并在初始化后继续当前发布意图
2. Story 清单必须存在：`{需求目录}/stories/stories-*.md`
3. 读取 `meta/workbench-state.md` 确认 `story-decompose` 已完成
4. 发布守卫：
   - `quality_gate.status` 必须为 `passed`，否则推荐回到 `/generate-prd`
   - `slice_status` 应为 `ready`，否则推荐回到 `/story-decompose` 修订切片
   - `uat_status` 必须为 `ready` 或 `waived`
5. 如果 `uat_status: pending`，使用 `AskUserQuestion` 让用户选择：
   - **先补 UAT 验收包（推荐）** — 回到 `/story-decompose`
   - **记录 UAT 豁免并继续** — 写入豁免原因后继续发布
   - **取消发布**

如果缺少 Story 清单，向用户说明并推荐先执行 `/story-decompose`。

---

## Step 1: 定位需求目录和 Story 文件

优先级：
1. `$ARGUMENTS` 指定的路径
2. `.product-manager/requirements/` 下最近创建的日期目录
3. 用 `AskUserQuestion` 让用户选择

读取 `meta/workbench-state.md` 获取 `slug` 和 `requirement_dir`。

---

## Step 2: 解析 Story 清单

读取 `{需求目录}/stories/stories-*.md`，解析出：

- Epic 列表：每个 `## Epic N: [模块名] — [价值描述]` 为一个 Epic
- Story 列表：每个 `### Story N-M: [标题]` 为一个 Story，归属于其所在 Epic
- 每个 Story 提取：用户故事、验收标准、来源、优先级

---

## Step 3: 检查幂等性

读取 `meta/jira-sync.yaml`（如存在）：

- 如果已有完整发布记录且无失败项，使用 `AskUserQuestion` 询问：
  - **增量同步变更部分** — 调用 `/req-sync`
  - **全量重新发布（会创建新 issue）**
  - **取消**
- 如果有 `status: failed` 的项，提示可以只重试失败项

**⏸️ 等待用户选择。**

---

## Step 4: 确定项目配置

从 `.requirement-mgmt/config.yaml` 读取 provider 信息。

使用 `AskUserQuestion` 让用户确认或输入：
- **Jira 项目 Key**（如 SCRUM）
- **Epic issuetype 名称**（默认 `Epic`）
- **Story issuetype 名称**（默认 `故事`，注意本地化）

**⏸️ 等待用户确认。**

---

## Step 5: 发布预览

向用户展示即将创建的 issue 清单：

```
📋 发布预览

项目：SCRUM
Epic 数量：3
Story 总数：12

Epic 1: 用户认证模块 — 安全登录体验
  ├─ Story 1-1: 邮箱密码登录 (P0)
  ├─ Story 1-2: 手机验证码登录 (P0)
  └─ Story 1-3: 记住登录状态 (P1)

Epic 2: ...
```

使用 `AskUserQuestion` 确认：
- **确认发布（推荐）**
- **修改后再发布**
- **取消**

**⏸️ 等待用户确认。**

---

## Step 6: 批量创建

### 6.1 创建 Epic

对每个 Epic：
1. 构造 JSON payload 文件（写入临时目录）：
   ```json
   {
     "fields": {
       "project": { "key": "<PROJECT_KEY>" },
       "summary": "<Epic 标题>",
       "issuetype": { "name": "<Epic type name>" },
       "description": "<Epic 下 Story 概览>"
     }
   }
   ```
2. 调用 `/req-create <json_file>`
3. 获取返回的 Jira key
4. 记录 local_id → jira_key 映射

### 6.2 创建 Story

对每个 Story：
1. 构造 JSON payload 文件：
   ```json
   {
     "fields": {
       "project": { "key": "<PROJECT_KEY>" },
       "summary": "<Story 标题>",
       "issuetype": { "name": "<Story type name>" },
       "parent": { "key": "<Epic jira_key>" },
       "priority": { "name": "<mapped priority>" },
       "description": "<用户故事>\n\n验收标准：\n<AC列表>\n\n来源：<PRD F#>"
     }
   }
   ```
2. 调用 `/req-create <json_file>`
3. 记录映射

### 6.3 可选：上传 PRD 附件

如果 PRD 文件存在，询问是否上传到首个 Epic：
- 调用 `/req-attach <epic_key> <prd_file>`

如果 UAT 验收包存在，询问是否上传到首个 Epic：
- 调用 `/req-attach <epic_key> <uat_pack_file>`

如果用户选择 UAT 豁免，必须把豁免原因写入 `meta/jira-sync.yaml` 的 `uat_waiver` 字段。

---

## Step 7: 写入映射文件

将发布结果写入 `{需求目录}/meta/jira-sync.yaml`，格式遵循 publish-principles.md 中的定义。

计算每个 Story 块的 md5 作为 source_hash，用于后续同步变更检测。

---

## Step 8: 更新工作台状态

更新 `meta/workbench-state.md`：
- `completed_steps` 追加 `req-publish`
- `artifact_paths.jira_sync` 指向 `meta/jira-sync.yaml`
- `spec_state: in-development`
- `state_history` 追加从 `approved` 到 `in-development` 的迁移记录

---

## Step 9: 发布结果展示

向用户展示：
- 成功创建的 issue 列表（key + summary）
- 失败项（如有）
- jira-sync.yaml 文件路径

使用 `AskUserQuestion` 提供后续选项：
- **在 Jira 中查看看板**
- **继续其他产品工作**
- **结束**

**⏸️ 等待用户选择。**

---

## 成功标准

### ✅ 成功
- Story 清单中的每个 Epic 和 Story 都在 Jira 中创建了对应 issue
- Epic → Story 的 parent 关系正确
- jira-sync.yaml 完整记录了映射关系
- 重复执行不会创建重复 issue

### ❌ 失败
- 不经用户确认就开始创建 issue
- Epic 和 Story 没有层级关系
- 没有写入 jira-sync.yaml
- 重复执行创建了重复 issue

<IMPORTANT>
发布是不可撤销的操作（会在 Jira 中创建真实 issue），必须在发布前让用户充分预览和确认。
</IMPORTANT>
