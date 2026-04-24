---
name: sp
description: Sprint 优先级工作台——按意图路由到 Backlog 梳理、优先级矩阵、Sprint 规划或完整流程
argument-hint: "<Sprint 规划任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# Sprint 优先级工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整 Backlog → Priority → Sprint 管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整三阶段管道
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "梳理 / backlog / 需求池" | backlog-only | 调用 `/backlog-grooming $ARGUMENTS` |
| "优先级 / RICE / WSJF / 排序" | priority-only | 调用 `/priority-matrix $ARGUMENTS` |
| "Sprint / 规划 / 排期 / 容量" | planning-only | 调用 `/sprint-planning $ARGUMENTS` |
| "快速检查 / 概览" | quick-check | → Step 3 |
| "完整规划 / 全套" 或复杂需求 | full-planning | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 完整 Sprint 规划流程（推荐）
- 仅 Backlog 梳理
- 仅优先级矩阵
- 仅 Sprint 规划
- 快速 Sprint 检查

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_sprint/{当前日期}-{缩写}/` 及子目录 `context/` `backlog/` `priority/` `planning/` `meta/`
4. **需求平台连接检查**：检查 requirement-mgmt 配置状态；若当前项目缺配置，用 `AskUserQuestion` 询问是否立即进入 `/req-setup` 初始化引导
5. 初始化 `meta/sprint-state.md`（workflow_mode、completed_steps、next_step）
6. 扫描已有目录，检查接续点（产物优先）

**⏸️ 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/sprint-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| Backlog 梳理 | `/backlog-grooming $ARGUMENTS` | `backlog/backlog-*.md` | 继续 / 重新梳理 / 结束 |
| 优先级矩阵 | `/priority-matrix $ARGUMENTS` | `priority/priority-matrix-*.md` | 继续 / 调整 / 回退 |
| Sprint 规划 | `/sprint-planning $ARGUMENTS` | `planning/sprint-plan-*.md` | 完成 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速 Sprint 检查

编排器内轻量执行：
1. 使用 Glob 扫描 `_sprint/*/backlog/backlog-*.md`，Read 最新文件，统计条目总数和就绪度分布（🟢/🟡/🔴 各多少）
2. 使用 Glob 扫描 `_sprint/*/priority/priority-matrix-*.md`，Read 最新文件，提取 Top 5 优先级条目及其得分
3. 使用 Read 加载 `_sprint/*/context/team-context.md`（如存在），对比团队容量与已排优先级条目的总故事点，计算供需比并标注预警级别（🟢 < 80% / 🟡 80-100% / 🔴 > 100%）

若上述文件均不存在，提示用户先执行 `/backlog-grooming` 生成基础数据。

使用 Write 生成精简报告到 `_sprint/quick-check-{日期}.md`，包含：容量快照 | Top 5 排序 | 供需预警。

---

## 断点恢复

1. 使用 Glob 扫描 `_sprint/*/meta/sprint-state.md`，Read 每个匹配文件，筛选 `next_step` 非 `done` 的目录为未完成任务
2. 对未完成任务，Read 其 `meta/sprint-state.md` 获取 `completed_steps` 和 `next_step`，再使用 Glob 检查对应阶段产出文件（`backlog/backlog-*.md`、`priority/priority-matrix-*.md`、`planning/sprint-plan-*.md`）是否存在，以产出文件为准推断实际进度
3. 使用 `AskUserQuestion` 向用户展示未完成任务列表及其进度，提供选项：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
优先级评分必须使用量化框架（RICE/WSJF），不可仅凭直觉排序。
Sprint 容量规划必须考虑缓冲（建议预留 15-20%）。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
