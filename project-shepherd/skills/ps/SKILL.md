---
name: ps
description: 项目守护者完整工作流——按顺序执行健康检查、障碍清除、速率跟踪
argument-hint: "<项目/迭代描述>"
---

# 项目守护者完整流程

入口编排技能，串联三个阶段完成从项目状态评估到速率趋势分析的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `sprint-12-review`、`q2-health`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_project-health/{当前日期}-{任务简写}/`（如 `_project-health/2026-04-06-sprint-12-review/`）
4. 创建子目录：`context/`、`health/`、`blockers/`、`velocity/`
5. 扫描 `_project-health/` 下已有的目录，向用户简要报告历史记录

---

## Step 1: 健康检查

调用 `/health-check $ARGUMENTS`

多维度评估项目当前健康状态，生成健康报告。

**阶段完成标志：** `{工作目录}/health/health-report-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 深入某个维度 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 障碍清除

调用 `/blocker-removal $ARGUMENTS`

识别、分类和制定当前项目阻塞的解决方案。

**阶段完成标志：** `{工作目录}/blockers/blocker-log-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 处理更多障碍 / 回到健康检查）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 速率跟踪

调用 `/velocity-tracking $ARGUMENTS`

分析团队速率趋势，生成燃尽/燃起图分析和交付预测。

**阶段完成标志：** `{工作目录}/velocity/velocity-report-*.md` 已生成。

速率报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
