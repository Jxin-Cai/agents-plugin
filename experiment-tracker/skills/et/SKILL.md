---
name: et
description: 实验跟踪完整流程——按顺序执行 A/B 测试设计、指标定义、结果分析
argument-hint: "<实验描述>"
---

# 实验跟踪完整流程

入口编排技能，串联三个阶段完成从实验设计到结果分析的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取实验描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `cta-color`、`checkout-flow`）
2. 使用 `AskUserQuestion` 工具向用户确认实验简写名称，提供你建议的缩写作为选项
3. 设定实验目录：`_experiments/{当前日期}-{实验简写}/`（如 `_experiments/2026-04-06-cta-color/`）
4. 创建子目录：`context/`、`designs/`、`metrics/`、`results/`
5. 扫描 `_experiments/` 下已有的实验目录，向用户简要报告

---

## Step 1: A/B 测试设计

调用 `/ab-test-design $ARGUMENTS`

定义实验假设、自变量与因变量、实验分组方案、样本量计算和实验时长估算。

**阶段完成标志：** `{实验目录}/designs/design-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整实验设计 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 指标定义

调用 `/metrics-definition`

构建实验指标体系，包括核心指标、辅助指标和护栏指标的定义与计算口径。

**阶段完成标志：** `{实验目录}/metrics/metrics-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整指标定义 / 回到实验设计）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 结果分析

调用 `/results-analysis`

对实验数据进行统计检验、效果量评估，输出决策建议。

**阶段完成标志：** `{实验目录}/results/analysis-*.md` 已生成。

结果分析保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_experiments/2026-04-06-cta-color/results/analysis-cta-color-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
