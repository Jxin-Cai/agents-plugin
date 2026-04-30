---
name: at
description: API 测试工作台——按意图路由到契约测试、集成测试、健康检查或完整流程
argument-hint: "<API 或服务名称及测试目标描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# API 测试工作台

用户传入的参数：`$ARGUMENTS`

先装配 API 测试任务，再带他进入对应 workflow。不是所有需求都需要直接落到契约 → 集成 → 健康检查三阶段管道。

**入口纪律**：除非用户明确点名 `/contract-test`、`/integration-test-plan`、`/api-health-check`，或明确要求“只做契约 / 只做联调 / 只做健康检查 / 只做快速扫描”，否则都先走 `/api-tester:at` 入口。像“帮我看看这个 API 怎么测”“发版前过一下服务验证”“先扫一下接口风险”这类泛化请求，一律先在入口完成任务装配。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整三阶段管道
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "契约 / schema / 消费者驱动 / Pact" | contract-only | 调用 `/contract-test $ARGUMENTS` |
| "集成测试 / 服务间 / mock / 端到端" | integration-only | 调用 `/integration-test-plan $ARGUMENTS` |
| "健康检查 / 监控 / 告警 / 探活" | health-only | 调用 `/api-health-check $ARGUMENTS` |
| "快速扫描 / API 概览 / 先看看定义" | quick-scan | 留在编排器内做 express 速览 |
| "继续上次 API 任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整测试 / 全套" 或复杂需求 | full-workflow | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `target_service`：目标服务 / API
- `protocol`：REST / GraphQL / gRPC / 事件 / WebSocket
- `target_env`：dev / staging / prod-like
- `deliverable`：契约兼容结论 / 集成计划 / 可用性方案 / 发版结论 / 快速分级
- `risk_focus`：兼容性 / 超时降级 / 依赖协作 / 可观测性 / API 安全
- `artifact_source`：OpenAPI / Proto / Postman / 代码路由 / 现成监控

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取 API/服务名，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_api-tests/{当前日期}-{缩写}/` 及子目录 `context/` `contracts/` `integration/` `health/` `meta/`
4. 初始化 `meta/test-state.md`（workflow_mode、target_service、protocol、target_env、completed_steps、next_step、last_artifact）
5. 扫描已有目录，检查接续点（产物优先）

**⏸️ 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/test-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 契约测试 | `/contract-test $ARGUMENTS` | `contracts/contract-*.md` | 继续 / 补充 / 结束 |
| 集成测试 | `/integration-test-plan $ARGUMENTS` | `integration/integration-test-plan-*.md` | 继续 / 回退 / 结束 |
| 健康检查 | `/api-health-check $ARGUMENTS` | `health/health-check-*.md` | 完成 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速 API 扫描

编排器内轻量执行：
1. **端点发现**：扫描 OpenAPI/Swagger、Proto、Postman 或代码中的路由定义
2. **契约速查**：判断请求/响应 schema、版本兼容策略和幂等性说明是否完整
3. **安全速查**：检查认证机制、敏感数据暴露、限流/CORS 等高风险缺口
4. **健康速查**：检查是否有健康检查端点、依赖检查、超时配置和告警入口

生成精简报告到 `_api-tests/quick-scan-{日期}.md`，并在结尾明确建议下一步路由：`contract-only / integration-only / health-only / full-workflow`。

---

## 断点恢复

1. 扫描 `_api-tests/` 下未完成目录
2. 先 Read `meta/test-state.md`，再结合 `contracts/` `integration/` `health/` 产物推断真实进度
3. 若状态记录与产物冲突，以产物为准
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配 API 测试任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
每个阶段完成后必须等待用户确认，不可自动推进到下一阶段。
契约测试必须验证 schema 合规性，不可仅测试 HTTP 状态码。
集成测试必须覆盖错误场景和超时场景。
没有同一上下文下的证据来源时，不要给出兼容性或可用性强结论。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
