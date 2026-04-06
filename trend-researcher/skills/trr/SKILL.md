---
name: trr
description: 趋势研究完整工作流——按顺序执行市场分析、竞争格局、技术趋势报告
argument-hint: "<研究主题描述>"
---

# 趋势研究完整流程

入口编排技能，串联三个阶段完成从市场分析到趋势报告的完整研究流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取研究主题，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `ai-saas`、`ev-battery`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_trend-research/{当前日期}-{任务简写}/`（如 `_trend-research/2026-04-06-ai-saas/`）
4. 创建子目录：`context/`、`market/`、`competitive/`、`trends/`
5. 扫描 `_trend-research/` 下已有的研究目录，向用户简要报告

---

## Step 1: 市场分析

调用 `/market-analysis $ARGUMENTS`

运用 Porter 五力、PESTEL 等框架分析市场结构、规模和驱动力。

**阶段完成标志：** `{工作目录}/market/market-analysis-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充市场分析 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 竞争格局

调用 `/competitive-landscape`

绘制竞争地图，对核心竞争对手进行 SWOT 分析和战略分组。

**阶段完成标志：** `{工作目录}/competitive/competitive-landscape-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充竞争分析 / 回到市场分析）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 技术趋势报告

调用 `/tech-trend-report`

基于 Gartner 技术成熟度曲线等框架，分析关键技术趋势并产出战略建议。

**阶段完成标志：** `{工作目录}/trends/tech-trend-report-*.md` 已生成。

报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
