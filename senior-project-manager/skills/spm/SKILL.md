---
name: spm
description: 高级项目经理完整工作流——按顺序执行风险评估、干系人地图、时间线规划
argument-hint: "<项目描述>"
---

# 高级项目经理完整流程

入口编排技能，串联三个阶段完成从项目风险识别到时间线交付的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取项目描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `platform-migration`、`app-launch`）
2. 使用 `AskUserQuestion` 工具向用户确认项目简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_project-mgmt/{当前日期}-{项目简写}/`（如 `_project-mgmt/2026-04-06-platform-migration/`）
4. 创建子目录：`context/`、`risks/`、`stakeholders/`、`timeline/`
5. 扫描 `_project-mgmt/` 下已有的项目目录，向用户简要报告

---

## Step 1: 风险评估

调用 `/risk-assessment $ARGUMENTS`

识别项目风险，通过概率-影响矩阵量化评估，制定应对策略。

**阶段完成标志：** `{项目目录}/risks/risk-register-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充更多风险 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 干系人地图

调用 `/stakeholder-map $ARGUMENTS`

基于权力-利益矩阵识别和分类干系人，制定差异化沟通策略。

**阶段完成标志：** `{项目目录}/stakeholders/stakeholder-map-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充更多干系人 / 回到风险评估）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 时间线规划

调用 `/timeline-planning $ARGUMENTS`

基于 WBS 分解项目范围，分析任务依赖，识别关键路径，输出里程碑计划。

**阶段完成标志：** `{项目目录}/timeline/timeline-plan-*.md` 已生成。

时间线保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
