---
name: bea
description: 后端架构设计完整流程——按顺序执行 API 设计、数据库建模、可扩展性评审
argument-hint: "<任务描述>"
---

# 后端架构设计完整流程

入口编排技能，串联三个阶段完成从需求理解到架构方案产出的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `order-system`、`user-auth`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_backend-arch/{当前日期}-{任务简写}/`（如 `_backend-arch/2026-04-06-order-system/`）
4. 创建子目录：`context/`、`api/`、`database/`、`scalability/`
5. 扫描 `_backend-arch/` 下已有的目录，向用户简要报告

---

## Step 1: API 设计

调用 `/api-design $ARGUMENTS`

基于需求进行 RESTful API 契约设计，定义资源、端点、请求响应结构和错误码体系。

**阶段完成标志：** `{工作目录}/api/api-design-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 修改 API 设计 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 数据库建模

调用 `/database-modeling $ARGUMENTS`

基于 API 设计中识别的资源，进行数据库建模、范式化设计和索引策略规划。

**阶段完成标志：** `{工作目录}/database/db-model-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 修改数据库模型 / 回到 API 设计）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 可扩展性评审

调用 `/scalability-review $ARGUMENTS`

对 API 设计和数据库模型进行可扩展性评审，识别瓶颈、制定扩展策略和容灾方案。

**阶段完成标志：** `{工作目录}/scalability/scalability-review-*.md` 已生成。

评审完成后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
