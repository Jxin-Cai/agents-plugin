---
name: uxr
description: UX 研究完整工作流——按顺序执行访谈指南生成、可用性测试计划、用户画像构建
argument-hint: "<研究任务描述>"
---

# UX 研究完整流程

入口编排技能，串联三个阶段完成从研究设计到用户画像产出的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取研究任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `onboarding-ux`、`checkout-flow`）
2. 使用 `AskUserQuestion` 工具向用户确认研究简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_ux-research/{当前日期}-{研究简写}/`（如 `_ux-research/2026-04-06-onboarding-ux/`）
4. 创建子目录：`context/`、`interviews/`、`tests/`、`personas/`
5. 扫描 `_ux-research/` 下已有的研究目录，向用户简要报告

---

## Step 1: 访谈指南

调用 `/interview-guide $ARGUMENTS`

设计结构化用户访谈脚本，包含暖场问题、核心问题、深挖追问和收尾流程。

**阶段完成标志：** `{研究目录}/interviews/interview-guide-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 修改访谈指南 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 可用性测试计划

调用 `/usability-test-plan`

基于访谈指南中的研究假设，制定可用性测试方案，包含任务设计、度量指标和实施流程。

**阶段完成标志：** `{研究目录}/tests/test-plan-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 修改测试计划 / 回到访谈指南）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 用户画像构建

调用 `/persona-builder`

基于访谈和测试的研究设计，用 JTBD 框架构建数据驱动的用户画像。

**阶段完成标志：** `{研究目录}/personas/persona-*.md` 已生成。

画像保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_ux-research/2026-04-06-onboarding-ux/personas/persona-primary-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
