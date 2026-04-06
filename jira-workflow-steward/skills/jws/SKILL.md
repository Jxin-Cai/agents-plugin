---
name: jws
description: Jira 工作流管理完整流程——按顺序执行工作流设计、问题分类、看板优化
argument-hint: "<任务描述>"
---

# Jira 工作流管理完整流程

入口编排技能，串联三个阶段完成从现状分析到看板优化的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `mobile-team-workflow`、`bug-triage-revamp`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_jira-workflow/{当前日期}-{任务简写}/`（如 `_jira-workflow/2026-04-06-mobile-team-workflow/`）
4. 创建子目录：`context/`、`workflows/`、`triage/`、`boards/`
5. 扫描 `_jira-workflow/` 下已有的目录，向用户简要报告

---

## Step 1: 工作流设计

调用 `/workflow-design $ARGUMENTS`

分析团队现状，设计或优化 Jira 工作流方案，输出状态图和转换规则。

**阶段完成标志：** `{任务目录}/workflows/workflow-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 重新设计工作流 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 问题分类

调用 `/issue-triage`

基于工作流设计的产出，建立问题分类标准、严重度/优先级矩阵和分诊流程。

**阶段完成标志：** `{任务目录}/triage/triage-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整分类标准 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 看板优化

调用 `/board-optimization`

基于工作流和分诊产出，优化 Scrum/Kanban 看板配置。

**阶段完成标志：** `{任务目录}/boards/board-*.md` 已生成。

看板方案保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
