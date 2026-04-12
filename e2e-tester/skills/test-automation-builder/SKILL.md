---
name: test-automation-builder
description: 将高价值测试路径沉淀为自动化脚本（api-script 或 e2e-script）
allowed-tools: Read, Glob, Write, Agent, AskUserQuestion, Bash(npx tsc --noEmit*), Bash(npx tsx*), Bash(npx playwright*)
---

# 自动化测试资产构建器

通过 subagent 将剧本 + prep + 报告转化为可回归的自动化脚本。

## 脚本类型

- **api-script**（`.test.ts`）：纯 API，`npx tsx` 执行，禁止 import playwright
- **e2e-script**（`.spec.ts`）：Playwright Test Runner，数据准备用 API，UI 仅用于无 API 替代的操作

## 流程

### Step 1: 收集上下文与资产检索

读取剧本、prep、task 文件、报告（重点提取 API 调用链）、`_shared/helpers/`、registry、asset-catalog。
判断已有脚本/helper/数据集是否可直接复用。

### Step 2: 适配性判断

- 适合 api-script：核心操作有 API + 状态可查询
- 适合 e2e-script：部分操作必须 UI + 验证点包含 UI 状态
- 不适合：纯前端逻辑 / 视觉判断 / 无可查询接口 → 明确告知，不硬生成

### Step 3: subagent 生成

> **条件加载**：此时读取 `references/script-conventions.md`（含 subagent prompt 模板）。registry schema 见 `skills/e2e/references/registry-conventions.md`。

通过 Agent 工具启动子 agent 生成脚本。

### Step 4: 校验

文件存在 + 元数据完整 + 断言与 oracle_types 一致 + api-script 无 playwright 依赖 / e2e-script 有 playwright 结构。

### Step 5: 更新注册表

同步更新 `registry/{domain}.yaml`、`registry/index.yaml`、`asset-catalog.md`、`task/index.md`。
必须登记：脚本路径、覆盖场景/case、依赖资产、source_paths、automation_confidence、限制说明。

## 约束

1. 必须用 subagent 生成
2. 无 prep 不生成
3. 不适合时明确拒绝
4. 注册表必须同步更新
5. 优先复用再新建
6. 资产必须可追溯

<IMPORTANT>
业务场景只能通过 UI 验证时，应生成 e2e-script，而不是在 limitations 标注"不支持"然后放弃。
</IMPORTANT>
