---
name: sp
description: Sprint 优先级工作台——先装配 Sprint 任务，再按意图路由到 Backlog 梳理、优先级矩阵、Sprint 规划、快速检查或完整流程
argument-hint: "<Sprint 规划任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# Sprint 优先级工作台

用户传入的参数：`$ARGUMENTS`

先装配 Sprint 优先级任务，再按意图路由到对应 workflow。不是所有需求都需要走完整 Backlog → Priority → Sprint 管道。

**入口纪律**：除非用户明确点名 `/backlog-grooming`、`/priority-matrix`、`/sprint-planning`，或明确要求“只做梳理 / 只做排序 / 只做规划 / 只做快速检查”，否则统一先走 `/sprint-prioritizer:sp` 入口。

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
| "梳理 / backlog / 需求池" | backlog-only | 调用 `/backlog-grooming $ARGUMENTS` |
| "优先级 / RICE / WSJF / 排序" | priority-only | 调用 `/priority-matrix $ARGUMENTS` |
| "Sprint / 规划 / 排期 / 容量" | planning-only | 调用 `/sprint-planning $ARGUMENTS` |
| "快速检查 / 概览 / 快扫" | quick-check | → Step 3 |
| "继续上次 Sprint 任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整规划 / 全套" 或复杂需求 | full-planning | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：backlog-only / priority-only / planning-only / quick-check / full-planning
- `workflow`：当前 workflow
- `goal`：本次 Sprint 决策目标
- `input_source`：用户口述 / 文档 / 本地文件
- `constraints`：截止日期 / 依赖 / 不可变约束
- `backlog_source`：需求池来源
- `framework`：RICE / WSJF / MoSCoW / 自定义
- `capacity_basis`：历史速率 / 人天 / 故事点
- `sync_intent`：是否需要回写外部系统或同步团队
- `current_stage`：当前阶段
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_sprint/{当前日期}-{缩写}/` 及子目录 `context/` `backlog/` `priority/` `planning/` `meta/`
4. **需求平台连接检查**：检查 requirement-mgmt 配置状态；若当前项目缺配置，用 `AskUserQuestion` 询问是否立即进入 `/req-setup` 初始化引导
5. 初始化 `meta/sprint-state.md`：

```markdown
workflow_mode: full-planning
task_type: full-planning
goal: {一句话目标}
input_source: user-input
constraints: []
backlog_source: unknown
framework: RICE
capacity_basis: recent-velocity
sync_intent: local-only
current_stage: backlog-grooming
completed_steps: []
next_step: backlog-grooming
updated_at: {YYYY-MM-DD}
```

6. 扫描已有目录，检查 `backlog/`、`priority/`、`planning/` 产物，产物优先于状态文件
7. 重新 Read `meta/sprint-state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/sprint-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| Backlog 梳理 | `/backlog-grooming $ARGUMENTS` | `backlog/backlog-*.md` 存在 | 继续 / 回退 / 结束 |
| 优先级矩阵 | `/priority-matrix $ARGUMENTS` | `priority/priority-matrix-*.md` 存在 | 继续 / 回退 / 结束 |
| Sprint 规划 | `/sprint-planning $ARGUMENTS` | `planning/sprint-plan-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能：
1. 用 Glob 扫描 `_sprint/` 下最近任务目录，优先读取最新产物和 `meta/sprint-state.md`
2. 汇总最近一次 Backlog 梳理的条目规模、优先级前 5、当前容量基线与供需预警
3. 若缺关键数据，则只收集最少信息并明确标注“待补数据”
4. 将结果写入 `_sprint/quick-check-{日期}.md`

使用 `AskUserQuestion`：深入梳理 / 深入排序 / 深入 Sprint 规划 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_sprint/` 下未完成目录
2. 先 Read `meta/sprint-state.md`，再核对 `backlog/`、`priority/`、`planning/` 产物
3. 恢复时以产物优先于状态文件；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配 Sprint 任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
优先级评分必须使用量化框架（RICE/WSJF 等），不可仅凭直觉排序。
Sprint 容量规划必须标注容量基线和缓冲（建议预留 15-20%）。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
