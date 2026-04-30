---
name: jws
description: Jira 工作流工作台——先装配 Jira 流程任务，再按意图路由到工作流设计、问题分类、看板优化、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# Jira 工作流工作台

用户传入的参数：`$ARGUMENTS`

先装配 Jira 流程任务，再按意图路由到对应 workflow。不是所有需求都需要走完整设计 → 分类 → 看板管道。

**入口纪律**：除非用户明确点名 `/workflow-design`、`/issue-triage`、`/board-optimization`，或明确要求“只做工作流 / 只做分诊 / 只做看板 / 只做快速检查”，否则统一先走 `/jira-workflow-steward:jws` 入口。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整三阶段管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "工作流 / 状态 / 转换 / 流程设计" | workflow-only | 调用 `/workflow-design $ARGUMENTS` |
| "分类 / 分诊 / triage / 优先级" | triage-only | 调用 `/issue-triage $ARGUMENTS` |
| "看板 / board / Kanban / WIP" | board-only | 调用 `/board-optimization $ARGUMENTS` |
| "快速检查 / 诊断 / 快扫" | quick-check | → Step 3 |
| "继续上次 Jira 任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整流程 / 全套" 或复杂需求 | full-workflow | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_slug`：任务简称
- `entry_intent`：入口诉求
- `workflow`：当前 workflow
- `deliverable`：希望产出的流程图 / 分诊规则 / 看板方案 / 研究包
- `team_mode`：Scrum / Kanban / Scrumban / SAFe / 未知
- `req_connected`：需求平台是否已连接
- `current_stage`：当前阶段
- `completed_stages`：已完成阶段
- `last_artifact`：最近产物
- `last_updated`：最近更新时间
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_jira-workflow/{当前日期}-{缩写}/` 及子目录 `context/` `workflows/` `triage/` `boards/` `meta/`
4. 检查 requirement-mgmt 配置状态；若当前项目缺配置，用 `AskUserQuestion` 询问是否立即进入 `/req-setup` 初始化引导
5. 初始化 `meta/workflow-state.md`：

```markdown
workflow_mode: full-workflow
task_slug: {缩写}
entry_intent: optimize-jira-flow
deliverable: workflow-pack
team_mode: unknown
req_connected: unknown
current_stage: workflow-design
completed_stages: []
last_artifact:
last_updated: {YYYY-MM-DD}
next_step: workflow-design
updated_at: {YYYY-MM-DD}
```

6. 扫描已有目录，检查 `workflows/`、`triage/`、`boards/` 产物，产物优先于状态文件
7. 重新 Read `meta/workflow-state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/workflow-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 工作流设计 | `/workflow-design $ARGUMENTS` | `workflows/workflow-*.md` 存在 | 继续 / 回退 / 结束 |
| 问题分类 | `/issue-triage $ARGUMENTS` | `triage/triage-*.md` 存在 | 继续 / 回退 / 结束 |
| 看板优化 | `/board-optimization $ARGUMENTS` | `boards/board-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速工作流诊断

编排器内轻量执行，不调用子技能：
1. 盘点最近任务中的状态设计、分诊规则、看板 WIP 线索
2. 输出状态数量、疑似瓶颈、WIP 偏差、需求平台连接状态
3. 若缺真实数据，仅生成带缺口说明的诊断卡，不臆造流程细节
4. 将结果写入 `_jira-workflow/quick-check-{日期}.md`

使用 `AskUserQuestion`：深入工作流 / 深入分诊 / 深入看板 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_jira-workflow/` 下未完成目录
2. 先 Read `meta/workflow-state.md`，再核对 `workflows/`、`triage/`、`boards/` 产物
3. 恢复时以产物优先于状态文件；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配 Jira 流程任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
工作流设计必须验证转换规则完整性（无死锁状态、无孤立状态）。
严重度与优先级必须作为独立维度定义，不可混用。
看板优化必须包含具体 WIP 数值上限，不可只写方向性建议。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
