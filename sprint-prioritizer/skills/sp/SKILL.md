---
name: sp
description: Sprint 优先级规划完整流程——按顺序执行 Backlog 梳理、优先级矩阵、Sprint 规划
argument-hint: "<Sprint 规划任务描述>"
---

# Sprint 优先级规划完整流程

入口编排技能，串联三个阶段完成从 Backlog 梳理到 Sprint 计划产出的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `q2-sprint3`、`release-v2`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_sprint/{当前日期}-{任务简写}/`（如 `_sprint/2026-04-06-q2-sprint3/`）
4. 创建子目录：`context/`、`backlog/`、`priority/`、`planning/`
5. 扫描 `_sprint/` 下已有的目录，向用户简要报告

---

## Step 1: Backlog 梳理

调用 `/backlog-grooming $ARGUMENTS`

结构化整理需求池，对每个条目进行就绪度检查和工作量估算。

**阶段完成标志：** `{工作目录}/backlog/backlog-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 重新梳理 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 优先级矩阵

调用 `/priority-matrix`

使用 RICE/WSJF/MoSCoW 等量化框架对 Backlog 条目进行优先级评分和排序。

**阶段完成标志：** `{工作目录}/priority/priority-matrix-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整优先级 / 回到 Backlog 梳理）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: Sprint 规划

调用 `/sprint-planning`

基于优先级排序和团队容量，生成可执行的 Sprint 计划。

**阶段完成标志：** `{工作目录}/planning/sprint-plan-*.md` 已生成。

Sprint 计划保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_sprint/2026-04-06-q2-sprint3/planning/sprint-plan-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
