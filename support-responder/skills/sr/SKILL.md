---
name: sr
description: 客户支持工作台——先装配支持任务，再按意图路由到工单处理、知识库、支持分析、快速分诊或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 客户支持工作台

用户传入的参数：`$ARGUMENTS`

先装配支持任务，再按意图路由到对应 workflow。不是所有需求都需要走完整工单 → 知识库 → 分析管道。

**入口纪律**：除非用户明确点名 `/ticket-resolution`、`/knowledge-base`、`/support-analytics`，或明确要求“只做工单 / 只做知识库 / 只做分析 / 只做快速分诊”，否则统一先走 `/support-responder:sr` 入口。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "工单 / SLA / 响应 / 升级" | ticket-only | 调用 `/ticket-resolution $ARGUMENTS` |
| "知识库 / FAQ / SOP / 文档" | kb-only | 调用 `/knowledge-base $ARGUMENTS` |
| "支持分析 / CSAT / FCR / 趋势" | analytics-only | 调用 `/support-analytics $ARGUMENTS` |
| "快速分诊 / 支持体检 / 快速概览" | quick-triage | → Step 3 |
| "继续上次支持任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整支持体系 / 全套" 或复杂需求 | full-support | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：ticket-only / kb-only / analytics-only / quick-triage / full-support
- `workflow`：当前 workflow
- `task_slug`：任务简称
- `task_dir`：任务目录简称
- `resume_mode`：自动恢复 / 指定阶段 / 重新开始
- `support_scope`：支持对象 / 产品范围 / 渠道范围
- `customer_segment`：客户等级 / 人群
- `support_channels`：邮箱 / IM / 工单系统 / 电话 / 社群
- `sla_target`：首响 / 解决时限 / 升级时限
- `sentiment_risk`：客户情绪与流失风险
- `known_facts`：已确认事实
- `open_questions`：待确认问题
- `kb_reuse_assets`：可复用知识库 / SOP / 宏模板
- `success_criteria`：成功判据
- `escalation_path`：升级路径
- `artifact_paths`：最近产物
- `state_history`：状态历史摘要
- `next_step`：下一步动作
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_support/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `tickets/` `kb/` `analytics/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-support
task_type: full-support
task_slug: {缩写}
task_dir: {缩写}
resume_mode: auto
support_scope: unknown
customer_segment: unknown
support_channels: []
sla_target: unknown
sentiment_risk: unknown
known_facts: []
open_questions: []
kb_reuse_assets: []
success_criteria: []
escalation_path: []
artifact_paths: []
state_history: []
current_stage: ticket-resolution
completed_steps: []
next_step: ticket-resolution
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `tickets/`、`kb/`、`analytics/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 工单处理 | `/ticket-resolution $ARGUMENTS` | `tickets/*` 存在 | 继续 / 回退 / 结束 |
| 知识库沉淀 | `/knowledge-base $ARGUMENTS` | `kb/*` 存在 | 继续 / 回退 / 结束 |
| 支持分析 | `/support-analytics $ARGUMENTS` | `analytics/*` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行），并区分“已确认事实 / 推断 / 待确认”。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速分诊

编排器内轻量执行，不调用子技能：
1. 优先读取最近任务的 `meta/state.md` 与 `tickets/`、`kb/`、`analytics/` 产物
2. 输出 SLA 覆盖、升级路径、知识库复用、重复问题信号四维速览
3. 结论必须区分“已确认事实”和“待验证推断”，不能把猜测当结论
4. 将结果写入 `_support/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入工单 / 深入知识库 / 深入分析 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_support/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `tickets/`、`kb/`、`analytics/` 产物
3. 恢复时以产物优先于状态文件；如已有工单方案但无知识库沉淀，下一步优先补知识库
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配支持任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
所有结论必须明确区分事实、推断与待确认项。
不确定时必须升级或求证，不能为追求响应速度而猜测答案。
重复问题必须沉淀成知识库条目或 SOP。
工单流程必须显式写出 SLA 与升级路径。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
