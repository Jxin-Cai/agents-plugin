---
name: sa
description: 软件架构设计完整流程——按顺序执行系统设计、架构评审、ADR 生成
argument-hint: "<架构任务描述>"
---

# 软件架构设计完整流程

入口编排技能，串联三个阶段完成从上下文分析到架构决策记录的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取架构任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `payment-gateway`、`user-auth-redesign`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_architecture/{当前日期}-{任务简写}/`（如 `_architecture/2026-04-06-payment-gateway/`）
4. 创建子目录：`context/`、`design/`、`adr/`
5. 扫描 `_architecture/` 下已有的目录，向用户简要报告

---

## Step 1: 系统设计

调用 `/system-design $ARGUMENTS`

基于 C4 模型进行分层架构设计，从系统上下文到组件级别。

**阶段完成标志：** `{工作目录}/design/system-design-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 修改设计 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 架构评审

调用 `/architecture-review`

基于 ATAM 方法对设计方案进行质量属性评审。

**阶段完成标志：** `{工作目录}/design/architecture-review-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续生成 ADR / 回到系统设计修改 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: ADR 生成

调用 `/adr-generation`

将架构评审中确定的关键决策写成 ADR 文档。

**阶段完成标志：** `{工作目录}/adr/adr-*.md` 已生成。

ADR 保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
