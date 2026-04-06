---
name: fs
description: 反馈综合分析完整流程——按顺序执行收集、情感分析、洞察提取
argument-hint: "<反馈分析任务描述>"
---

# 反馈综合分析完整流程

入口编排技能，串联三个阶段完成从反馈收集到可操作洞察的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `app-v3-launch`、`checkout-complaints`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_feedback/{当前日期}-{任务简写}/`（如 `_feedback/2026-04-06-app-v3-launch/`）
4. 创建子目录：`context/`、`raw-feedback/`、`analysis/`、`insights/`
5. 扫描 `_feedback/` 下已有的任务目录，向用户简要报告

---

## Step 1: 反馈收集

调用 `/feedback-collection $ARGUMENTS`

多渠道收集和结构化整理用户反馈数据，建立统一的反馈数据集。

**阶段完成标志：** `{工作目录}/raw-feedback/feedback-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充更多反馈 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 情感分析

调用 `/sentiment-analysis`

对收集的反馈进行情感分类、NPS/CSAT 评分分析和主题聚类。

**阶段完成标志：** `{工作目录}/analysis/sentiment-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 深入分析某个主题 / 回到反馈收集补充数据）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 洞察提取

调用 `/insight-extraction`

从分析结果中提炼可操作的产品洞察，输出优先级矩阵和决策建议。

**阶段完成标志：** `{工作目录}/insights/insights-*.md` 已生成。

洞察报告保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_feedback/2026-04-06-app-v3-launch/insights/insights-app-v3-launch-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
