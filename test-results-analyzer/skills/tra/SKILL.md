---
name: tra
description: 测试结果分析完整流程——按顺序执行覆盖率分析、失败分析、质量报告生成
argument-hint: "<测试分析任务描述>"
---

# 测试结果分析完整流程

入口编排技能，串联三个阶段完成从测试数据收集到质量报告产出的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `login-api`、`payment-module`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_test-analysis/{当前日期}-{任务简写}/`（如 `_test-analysis/2026-04-06-login-api/`）
4. 创建子目录：`context/`、`coverage/`、`failures/`、`reports/`
5. 扫描 `_test-analysis/` 下已有的分析目录，向用户简要报告

---

## Step 1: 覆盖率分析

调用 `/coverage-analysis $ARGUMENTS`

解析测试覆盖率报告，识别覆盖盲区，给出覆盖率改进的优先级建议。

**阶段完成标志：** `{工作目录}/coverage/coverage-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 重新分析覆盖率 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 失败分析

调用 `/failure-analysis $ARGUMENTS`

结构化诊断测试失败的根本原因，识别失败模式和缺陷聚集区域。

**阶段完成标志：** `{工作目录}/failures/failure-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续生成质量报告 / 再来一轮深度分析 / 回到覆盖率分析）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 质量报告

调用 `/quality-report $ARGUMENTS`

基于覆盖率分析和失败分析的产出，生成综合质量报告，含 KPI 度量、质量门控判定和改进建议。

**阶段完成标志：** `{工作目录}/reports/quality-report-*.md` 已生成。

质量报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
