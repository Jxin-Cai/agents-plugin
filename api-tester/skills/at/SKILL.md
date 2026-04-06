---
name: at
description: API 测试完整工作流——按顺序执行契约测试、集成测试计划、API 健康检查
argument-hint: "<API 或服务名称及测试目标描述>"
---

# API 测试专家完整流程

入口编排技能，串联三个阶段完成从 API 契约定义到健康监控的完整测试流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取 API/服务描述，生成简短英文缩写（2-4 词，连字符连接，如 `order-api`、`payment-gateway`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_api-tests/{当前日期}-{任务简写}/`（如 `_api-tests/2026-04-06-order-api/`）
4. 创建子目录：`context/`、`contracts/`、`integration/`、`health/`
5. 扫描 `_api-tests/` 下已有的目录，向用户简要报告

---

## Step 1: 契约测试

调用 `/contract-test $ARGUMENTS`

定义消费者驱动的 API 契约，生成契约测试用例和验证方案。

**阶段完成标志：** `{工作目录}/contracts/contract-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充契约 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 集成测试计划

调用 `/integration-test-plan`

基于契约定义，制定服务间集成测试策略、用例和 Mock 方案。

**阶段完成标志：** `{工作目录}/integration/integration-test-plan-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充测试用例 / 回到契约测试）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: API 健康检查

调用 `/api-health-check`

设计健康检查端点、监控指标和告警规则。

**阶段完成标志：** `{工作目录}/health/health-check-*.md` 已生成。

健康检查方案保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
