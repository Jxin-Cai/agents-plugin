---
name: bea
description: 后端架构工作台——按意图路由到对应 workflow（API 设计 / 数据库建模 / 可扩展性评审 / 微服务 / 技术债 / 快速扫描）
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Edit", "Bash(mkdir*|ls*|find*|wc*)", "Glob", "Grep", "AskUserQuestion"]
---

# 后端架构工作台

用户传入的参数：`$ARGUMENTS`

先装配任务，再按意图路由到对应 workflow。不是所有需求都需要直接落到完整管道。

**入口纪律**：除非用户明确点名 `/api-design`、`/database-modeling`、`/scalability-review`，或明确要求“只做微服务设计 / 只做技术债评估 / 只做快速扫描”，否则都先走 `/backend-architect:bea` 入口。像“帮我设计这个系统”“评估一下当前后端方案”“看看这次重构怎么落地”这类泛化请求，一律先完成任务装配，再决定 workflow。

---

## Step 0: 任务装配与路由

### 显式快路由

根据 `$ARGUMENTS` 判断工作类型：

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "API 设计 / 接口 / 端点 / 契约" | api-design-only | 调用 `/api-design $ARGUMENTS` |
| "数据库 / 建模 / 表结构 / ER" | db-modeling-only | 调用 `/database-modeling $ARGUMENTS` |
| "扩展性 / 瓶颈 / 容灾 / CAP" | scalability-only | 调用 `/scalability-review $ARGUMENTS` |
| "微服务 / 服务拆分 / 领域驱动" | microservice-design | → Step 4 |
| "技术债 / 重构 / 代码腐化" | tech-debt-assessment | → Step 5 |
| "快速扫描 / 架构体检 / 健康检查" | quick-scan | → Step 3 |
| "继续上次架构任务 / 恢复任务" | resume | 优先进入断点恢复 |

### 任务装配

如果无法唯一判断，使用 `AskUserQuestion` 一次性补齐最小任务卡：
- `goal`：要交付 API 方案 / 数据模型 / 扩展性评审 / 微服务方案 / 技术债路线 / 全套方案
- `constraints`：QPS / SLA / 数据量级 / 上线时间 / 团队规模
- `risk_focus`：一致性 / 成本 / 可观测性 / 容灾 / 迁移风险
- `artifact_expectation`：方案草图 / 评审意见 / ADR 候选 / 快速诊断

装配完成后再让用户确认：
- 完整架构流程（推荐）— API + 数据库 + 扩展性评审
- 仅 API 设计
- 仅数据库建模
- 仅可扩展性评审
- 微服务架构设计
- 技术债评估
- 快速架构扫描

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整架构——初始化

使用 Read 工具加载 `references/full-arch-playbook.md`，严格遵守其中规则。

### 1.1 工作目录创建

1. 从 `$ARGUMENTS` 提取任务描述，生成简短英文缩写（2-4 词，如 `order-system`）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建目录结构：`_backend-arch/{当前日期}-{缩写}/`，子目录：`context/`、`api/`、`database/`、`scalability/`、`meta/`
4. 初始化 `meta/arch-state.md`：

```markdown
workflow_mode: full-architecture
slug: {缩写}
completed_steps: []
next_step: api-design
goal: {一句话目标}
constraints: []
risk_focus: []
artifact_paths: {}
decisions: []
```

5. 扫描 `_backend-arch/` 已有目录，简要报告

### 1.2 接续判断

检查实际产物文件（产物优先于 state 记录）：

| 产物检查 | 推荐动作 |
|----------|---------|
| 无 `api/api-design-*.md` | 从 API 设计开始 |
| 有 API 无 `database/db-model-*.md` | 从数据库建模开始 |
| 有 DB 无 `scalability/scalability-review-*.md` | 从可扩展性评审开始 |
| 三阶段产物齐全 | 展示汇总 |

使用 `AskUserQuestion` 确认从哪里开始。**⏸️ 等待用户选择。**

---

## Step 2: 完整架构——串联执行

按顺序调用子技能，每阶段完成后更新 `meta/arch-state.md`：

| 阶段 | 调用 | 完成标志 | 阶段摘要 |
|------|------|---------|---------|
| API 设计 | `/api-design $ARGUMENTS` | `api/api-design-*.md` 存在 | `meta/api-summary.md`（≤20 行） |
| 数据库建模 | `/database-modeling $ARGUMENTS` | `database/db-model-*.md` 存在 | `meta/db-summary.md`（≤20 行） |
| 可扩展性评审 | `/scalability-review $ARGUMENTS` | `scalability/scalability-review-*.md` 存在 | 展示所有产出绝对路径 |

每阶段完成后：
1. 更新 state（completed_steps 追加、next_step 更新）
2. 使用 `AskUserQuestion`（选项：继续下一阶段 / 修改当前阶段 / 回到上一阶段 / 结束流程）

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速架构扫描

不调用子技能，在编排器内完成轻量评估。

1. 用 Glob 扫描项目结构，识别技术栈（框架、数据库、缓存、消息队列）
2. 用 Grep 检查架构健康指标：

| 检查项 | 搜索模式 | 风险信号 |
|--------|---------|---------|
| 错误处理 | `catch.*TODO\|catch.*pass` | 吞异常 |
| 硬编码配置 | `localhost\|127\.0\.0\.1` | 配置未外部化 |
| SQL 拼接 | `"SELECT.*\+\|f"SELECT` | SQL 注入风险 |
| 单点依赖 | 无重试/熔断关键词 | 可用性风险 |

3. 输出扫描报告（≤30 行），按风险等级（高/中/低）排序
4. 使用 `AskUserQuestion` 询问：进入完整架构流程 / 针对某个风险点深入分析 / 结束

---

## Step 4: 微服务架构设计

使用 Read 工具加载 `references/microservice-playbook.md`，严格遵守其中规则。

1. 确定工作目录（复用已有或创建新目录），创建 `microservice/` 子目录
2. 按 playbook 引导：领域边界识别 → 服务通信设计 → 数据隔离策略 → 部署与可观测性
3. 产出保存到 `{工作目录}/microservice/microservice-design-{日期}.md`
4. 更新 `meta/arch-state.md`

---

## Step 5: 技术债评估

使用 Read 工具加载 `references/tech-debt-playbook.md`，严格遵守其中规则。

1. 确定工作目录（复用已有或创建新目录），创建 `tech-debt/` 子目录
2. 按 playbook 引导：技术债盘点 → 影响评估 → 还债计划
3. 产出保存到 `{工作目录}/tech-debt/tech-debt-assessment-{日期}.md`
4. 更新 `meta/arch-state.md`

---

## 断点恢复

新会话进入时，如果 `_backend-arch/` 下已有任务目录：

1. 优先识别用户是否明确要“继续上次任务 / 恢复任务”
2. 读取最近任务的 `meta/arch-state.md`
3. 用 Glob 检查实际产物文件（产物优先于 state 文件）：
   - `api/api-design-*.md`
   - `database/db-model-*.md`
   - `scalability/scalability-review-*.md`
   - `microservice/microservice-design-*.md`
   - `tech-debt/tech-debt-assessment-*.md`
4. 若状态文件与产物冲突，以产物为准回推阶段并更新推荐下一步
5. 向用户展示当前进度，使用 `AskUserQuestion` 确认：继续未完成任务 / 开始新任务

<IMPORTANT>
## 质量硬规则

### 编排纪律
1. 工作台职责是"先装配后路由 + 接续"，不默认跑完整 API → DB → Scalability 管道
2. 微服务设计、技术债评估和快速扫描是独立 workflow，不经过三阶段管道
3. 每个阶段完成后必须等待用户确认再进入下一阶段
4. 产出文件与状态文件冲突时，以产出文件为准
5. 恢复时必须先读状态、再校验产物，不可只凭对话记忆推进

### 后端架构专业规则
6. 每个扩展方案必须同时标注实施成本和预期收益——禁止无代价分析的"银弹"推荐
7. API 端点必须同时定义正常响应和错误响应（含 HTTP 状态码 + 业务错误码）——只有 happy path 的设计不合格
8. 数据库反范式化决策必须记录原因、读写比数据和一致性保障方案——"为了性能"不是充分理由
9. CAP 权衡必须关联到具体业务场景（如"支付->CP，推荐->AP"），不可笼统选择
</IMPORTANT>
