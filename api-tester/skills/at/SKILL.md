---
name: at
description: API 测试工作台——按意图路由到契约测试、集成测试、健康检查或完整流程
argument-hint: "<API 或服务名称及测试目标描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# API 测试工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整契约 → 集成 → 健康检查管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整三阶段管道
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "契约 / schema / 消费者驱动 / Pact" | contract-only | 调用 `/contract-test $ARGUMENTS` |
| "集成测试 / 服务间 / mock / 端到端" | integration-only | 调用 `/integration-test-plan $ARGUMENTS` |
| "健康检查 / 监控 / 告警 / 探活" | health-only | 调用 `/api-health-check $ARGUMENTS` |
| "快速扫描 / API 概览" | quick-scan | → Step 3 |
| "完整测试 / 全套" 或复杂需求 | full-workflow | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 完整 API 测试流程（推荐）
- 仅契约测试
- 仅集成测试计划
- 仅健康检查设计
- 快速 API 扫描

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取 API/服务名，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_api-tests/{当前日期}-{缩写}/` 及子目录 `context/` `contracts/` `integration/` `health/` `meta/`
4. 初始化 `meta/test-state.md`（workflow_mode、completed_steps、next_step）
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
1. **端点发现**：扫描 OpenAPI/Swagger 或代码中的路由定义
2. **契约速查**：请求/响应 schema 完整性
3. **安全速查**：认证机制、敏感数据暴露、CORS 配置
4. **健康速查**：是否有健康检查端点、超时配置

生成精简报告到 `_api-tests/quick-scan-{日期}.md`。

---

## 断点恢复

1. 扫描 `_api-tests/` 下未完成目录
2. Read `meta/test-state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
每个阶段完成后必须等待用户确认，不可自动推进到下一阶段。
契约测试必须验证 schema 合规性，不可仅测试 HTTP 状态码。
集成测试必须覆盖错误场景和超时场景。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
