---
name: bea
description: 后端架构工作台——按意图路由到对应 workflow（API 设计 / 数据库建模 / 可扩展性评审 / 微服务设计 / 完整架构 / 技术债评估）
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Edit", "Bash", "Glob", "Grep", "AskUserQuestion"]
---

# 后端架构工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整 API → DB → Scalability 管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- ✅ 使用 `AskUserQuestion` 让用户做选择，不假设
- 🚫 不默认跑完整 API → DB → Scalability 管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 1: 路由 Workflow

根据 `$ARGUMENTS` 判断工作类型：

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "API 设计 / 接口 / 端点 / 契约" | api-design-only | 调用 `/api-design $ARGUMENTS` |
| "数据库 / 建模 / 表结构 / ER" | db-modeling-only | 调用 `/database-modeling $ARGUMENTS` |
| "扩展性 / 瓶颈 / 容灾 / CAP" | scalability-review | 调用 `/scalability-review $ARGUMENTS` |
| "微服务 / 服务拆分 / 领域驱动" | microservice-design | → Step 3 |
| "技术债 / 重构 / 代码腐化" | tech-debt-assessment | → Step 4 |
| "完整架构 / 全套方案" 或复杂需求 | full-architecture | → Step 2 |

如果无法唯一判断，使用 `AskUserQuestion` 让用户选择：
- 完整架构流程（推荐）— API + 数据库 + 扩展性评审
- 仅 API 设计
- 仅数据库建模
- 仅可扩展性评审
- 微服务架构设计
- 技术债评估

**⏸️ 等待用户选择。**

---

## Step 2: 完整架构流程

使用 Read 工具加载：`references/full-arch-playbook.md`，严格遵守其中规则。

### 2.1 初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `order-system`）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建工作目录：`_backend-arch/{当前日期}-{缩写}/`
4. 创建子目录：`context/`、`api/`、`database/`、`scalability/`、`meta/`
5. 初始化 `meta/arch-state.md`：

```markdown
workflow_mode: full-architecture
slug: {缩写}
completed_steps: []
next_step: api-design
artifact_paths: {}
decisions: []
```

6. 扫描 `_backend-arch/` 已有目录，简要报告

### 2.2 接续判断

检查 `meta/arch-state.md` 和实际产物文件（产物优先）：

| 产物检查 | 推荐动作 |
|----------|---------|
| 无 `api/api-design-*.md` | 从 API 设计开始 |
| 有 API 无 `database/db-model-*.md` | 从数据库建模开始 |
| 有 DB 无 `scalability/scalability-review-*.md` | 从可扩展性评审开始 |
| 三阶段产物齐全 | 展示汇总 |

向用户展示接续状态，使用 `AskUserQuestion` 确认从哪里开始。

**⏸️ 等待用户选择。**

### 2.3 串联执行

按顺序调用子技能，每阶段完成后更新 `meta/arch-state.md`：

1. **API 设计** — 调用 `/api-design $ARGUMENTS`
   - 完成标志：`api/api-design-*.md` 存在
   - 写入阶段摘要到 `meta/api-summary.md`（不超过 20 行）
   - 更新 state：`completed_steps` 加入 `api-design`，`next_step` 设为 `database-modeling`

2. **数据库建模** — 调用 `/database-modeling $ARGUMENTS`
   - 完成标志：`database/db-model-*.md` 存在
   - 写入阶段摘要到 `meta/db-summary.md`（不超过 20 行）
   - 更新 state：`completed_steps` 加入 `database-modeling`，`next_step` 设为 `scalability-review`

3. **可扩展性评审** — 调用 `/scalability-review $ARGUMENTS`
   - 完成标志：`scalability/scalability-review-*.md` 存在
   - 更新 state：`completed_steps` 加入 `scalability-review`，`next_step` 设为 `done`
   - 完成后展示所有产出的 **绝对路径**

每阶段完成后使用 `AskUserQuestion`（选项：继续下一阶段 / 修改当前阶段 / 回到上一阶段 / 结束流程）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 微服务架构设计

使用 Read 工具加载：`references/microservice-playbook.md`，严格遵守其中规则。

1. 确定工作目录（复用已有或创建新目录）
2. 创建 `microservice/` 子目录
3. 按 playbook 引导用户完成：领域边界识别 → 服务通信设计 → 数据隔离策略 → 部署与可观测性
4. 产出保存到：`{工作目录}/microservice/microservice-design-{日期}.md`
5. 更新 `meta/arch-state.md`

---

## Step 4: 技术债评估

使用 Read 工具加载：`references/tech-debt-playbook.md`，严格遵守其中规则。

1. 确定工作目录（复用已有或创建新目录）
2. 创建 `tech-debt/` 子目录
3. 按 playbook 引导用户完成：技术债盘点 → 影响评估 → 还债计划
4. 产出保存到：`{工作目录}/tech-debt/tech-debt-assessment-{日期}.md`
5. 更新 `meta/arch-state.md`

---

## 成功/失败指标

### 成功
- 能识别用户意图并路由到正确的 workflow
- 模糊意图时用 `AskUserQuestion` 确认
- 完整流程有状态文件支撑接续
- 每阶段完成后等待用户确认
- 只加载当前 workflow 需要的 references

### 失败
- 所有请求都走完整 API → DB → Scalability 管道
- 没有状态文件就推进完整流程
- 入口全量加载所有 references
- 没有等用户确认就进入下一步

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
微服务设计和技术债评估是独立 workflow，不经过 API → DB → Scalability 管道。
每个阶段完成后必须等待用户确认再进入下一阶段。
</IMPORTANT>
