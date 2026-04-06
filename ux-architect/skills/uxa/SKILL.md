---
name: uxa
description: UX 架构分析完整流程——按顺序执行信息架构、用户流程分析、交互审计
argument-hint: "<产品或功能描述>"
---

# UX 架构分析完整流程

入口编排技能，串联三个阶段完成从信息架构到交互审计的完整 UX 架构分析流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `ecommerce-nav`、`dashboard-ia`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_ux-arch/{当前日期}-{任务简写}/`（如 `_ux-arch/2026-04-06-ecommerce-nav/`）
4. 创建子目录：`context/`、`ia/`、`flows/`、`interaction/`
5. 扫描 `_ux-arch/` 下已有的目录，向用户简要报告

---

## Step 1: 信息架构

调用 `/information-architecture $ARGUMENTS`

分析产品的内容结构、导航体系、分类法和标签系统，产出站点地图和信息架构方案。

**阶段完成标志：** `{工作目录}/ia/ia-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整信息架构 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 用户流程分析

调用 `/user-flow-analysis $ARGUMENTS`

基于信息架构的产出，映射关键任务的用户流程，识别摩擦点和断裂点。

**阶段完成标志：** `{工作目录}/flows/flow-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充更多流程 / 回到信息架构）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 交互审计

调用 `/interaction-audit $ARGUMENTS`

基于启发式原则对交互设计进行系统评估，输出问题清单和优化建议。

**阶段完成标志：** `{工作目录}/interaction/audit-*.md` 已生成。

审计报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
