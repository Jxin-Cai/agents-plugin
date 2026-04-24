---
name: req-sync
description: 检测本地 Story 文件变更并同步到 Jira——增量更新已发布 issue 的内容
argument-hint: "<需求目录路径或 slug>"
allowed-tools: ["Read", "Bash(bash*)", "Write", "AskUserQuestion", "Skill"]
---

# 需求同步到 Jira

检测本地 Story 清单相对于上次发布时的变更，将修改过的 Story 同步更新到 Jira 对应的 issue。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

使用 Read 工具加载以下引用文件：

- `../req-publish/references/publish-principles.md` — 复用字段映射和 jira-sync.yaml 格式定义

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 只更新有变更的 Story，不做全量覆盖
- ✅ 同步前展示变更差异，用 `AskUserQuestion` 让用户确认
- ✅ 同步后更新 jira-sync.yaml 的 hash 和时间戳
- ✅ 更新 issue 必须调用 `/req-update`
- ✅ 首次缺配置时必须通过 `/req` 或 `/req-setup` 初始化并保存项目级 `.requirement-mgmt/config.yaml`
- 🚫 不自动做状态流转（除非用户明确要求）
- 🚫 不创建新 issue（新增的 Story 应通过 `/req-publish` 处理）
- 🚫 不直接 `curl` Jira REST，不直接调用 `core/requirement-mgmt/skills/_providers/*/api.sh`

---

## 前置条件

1. 需求平台配置必须可用。同步前先通过 `/req` 的配置检测链路确认；若当前项目还没有 `.requirement-mgmt/config.yaml`，调用 `/req` 或 `/req-setup` 完成初始化，并在初始化后继续当前同步意图
2. `meta/jira-sync.yaml` 必须存在（说明已经发布过）
3. 如果不存在，提示用户先执行 `/req-publish`

---

## Step 1: 加载映射和当前文件

1. 读取 `meta/jira-sync.yaml`
2. 读取 `stories/stories-*.md`（当前版本）
3. 解析出每个 Story 块的内容和 md5

---

## Step 2: 检测变更

对比每个 Story 的当前 md5 与 jira-sync.yaml 中记录的 source_hash：

- `source_hash` 不一致 → 标记为"已变更"
- 新增的 Story（在 jira-sync.yaml 中没有对应 local_id） → 标记为"新增"
- jira-sync.yaml 中有但当前文件中已删除的 Story → 标记为"已移除"

---

## Step 3: 展示变更概览

```
📊 同步检测结果

已变更（将更新到 Jira）：
  ├─ Story 1-2: 手机验证码登录 → SCRUM-12
  └─ Story 2-1: 商品搜索 → SCRUM-15

新增（需通过 /req-publish 发布）：
  └─ Story 3-1: 订单导出

未变更：8 个 Story
```

使用 `AskUserQuestion` 确认：
- **同步已变更的 Story（推荐）**
- **查看具体变更内容**
- **取消**

**⏸️ 等待用户确认。**

---

## Step 4: 执行同步

对每个"已变更"的 Story：

1. 重新组装 description（用户故事 + 验收标准 + 来源）
2. 构造更新 payload JSON 文件：
   ```json
   {
     "fields": {
       "summary": "<更新后的 Story 标题>",
       "description": "<更新后的完整描述>"
     }
   }
   ```
3. 调用 `/req-update <jira_key> <json_file>`
4. 更新 jira-sync.yaml 中对应项的 `source_hash` 和 `last_synced`

---

## Step 5: 更新映射文件

将更新后的 jira-sync.yaml 写回 `meta/jira-sync.yaml`。

---

## Step 6: 同步结果展示

向用户展示：
- 成功更新的 issue 列表
- 失败项（如有）
- 新增项提示（需要 `/req-publish` 补发布）
- 已移除项提示（Jira 中的 issue 不会自动删除，建议手动处理）

使用 `AskUserQuestion` 提供后续选项：
- **补发布新增的 Story** — 调用 `/req-publish`
- **继续其他产品工作**
- **结束**

**⏸️ 等待用户选择。**

---

## 成功标准

### ✅ 成功
- 仅变更的 Story 被更新，未变更的不受影响
- jira-sync.yaml 的 hash 和时间戳正确刷新
- 用户能清楚看到什么被更新了

### ❌ 失败
- 全量覆盖所有 issue（不管有没有变更）
- 没有更新 jira-sync.yaml
- 不经用户确认就执行同步

<IMPORTANT>
同步是增量操作，只更新有变更的内容。全量操作请使用 /req-publish。
</IMPORTANT>
