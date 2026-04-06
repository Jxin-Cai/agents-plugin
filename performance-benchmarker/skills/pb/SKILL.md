---
name: pb
description: 性能基准测试完整流程——按顺序执行负载测试计划、性能分析指南、优化报告
argument-hint: "<任务描述>"
---

# 性能基准测试完整流程

入口编排技能，串联三个阶段完成从测试规划到优化报告的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `api-perf`、`checkout-load`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_performance/{当前日期}-{任务简写}/`（如 `_performance/2026-04-06-api-perf/`）
4. 创建子目录：`context/`、`load-tests/`、`profiling/`、`reports/`
5. 扫描 `_performance/` 下已有的目录，向用户简要报告

---

## Step 1: 负载测试计划

调用 `/load-test-plan $ARGUMENTS`

设计分阶段压测方案，定义工作负载模型、SLO 目标和测试场景。

**阶段完成标志：** `{任务目录}/load-tests/load-test-plan-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整测试计划 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 性能分析指南

调用 `/profiling-guide`

基于测试计划的产出，系统化定位 CPU/内存/I/O 瓶颈，生成分析指南。

**阶段完成标志：** `{任务目录}/profiling/profiling-guide-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充分析 / 回到测试计划）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 优化报告

调用 `/optimization-report`

将测试数据和分析结果整合为结构化的优化报告。

**阶段完成标志：** `{任务目录}/reports/optimization-report-*.md` 已生成。

报告保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_performance/2026-04-06-api-perf/reports/optimization-report-api-perf-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
