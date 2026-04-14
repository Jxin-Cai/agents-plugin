---
name: test-automation-builder
description: 将高价值测试路径沉淀为自动化脚本（api-script 或 e2e-script）
allowed-tools: Read, Glob, Write, Agent, AskUserQuestion, Bash(mkdir*), Bash(npx tsc --noEmit*), Bash(npx tsx*), Bash(npx playwright*)
---

# 自动化测试资产构建器

通过 subagent 将剧本 + prep + 报告转化为可回归的自动化脚本。

## 脚本类型

- **api-script**（`.test.ts`）：纯 API，`npx tsx` 执行，禁止 import playwright
- **e2e-script**（`.spec.ts`）：Playwright Test Runner，数据准备用 API，UI 仅用于无 API 替代的操作

## 流程

### Step 1: 收集上下文与资产检索

读取 `.e2e-tests/tasks/{date}-{slug}/scenarios/` 下的剧本、`.e2e-tests/tasks/{date}-{slug}/prep/` 下的方案、`.e2e-tests/tasks/{date}-{slug}/task/task.md`、`.e2e-tests/tasks/{date}-{slug}/reports/` 下的报告（重点提取 API 调用链）、`.e2e-tests/shared/helpers/`、`.e2e-tests/shared/registry/`、`.e2e-tests/shared/asset-catalog.md`。
判断已有脚本/helper/数据集是否可直接复用。

### Step 2: 适配性判断

- 适合 api-script：核心操作有 API + 状态可查询
- 适合 e2e-script：部分操作必须 UI + 验证点包含 UI 状态
- 不适合：纯前端逻辑 / 视觉判断 / 无可查询接口 → 明确告知，不硬生成

### Step 3: subagent 生成

> **条件加载**：此时读取 `references/script-conventions.md`（含 subagent prompt 模板）。registry schema 见 `skills/e2e/references/registry-conventions.md`。

写入前确保目录存在：`mkdir -p .e2e-tests/shared/automation/{domain}`

通过 Agent 工具启动子 agent 生成脚本，写入 `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.{test|spec}.ts`。

### Step 4: 校验

文件存在 + 元数据完整 + 断言与 oracle_types 一致 + api-script 无 playwright 依赖 / e2e-script 有 playwright 结构。

### Step 5: 更新注册表与索引

同步更新：
- `.e2e-tests/shared/registry/{domain}.yaml`（脚本条目）
- `.e2e-tests/shared/registry/index.yaml`（全局索引 script_count + last_updated）
- `.e2e-tests/shared/asset-catalog.md`（跨域脚本参考）
- `.e2e-tests/tasks/{date}-{slug}/task/index.md`（已沉淀资产区块）

必须登记：脚本路径、覆盖场景/case、依赖资产、source_paths、automation_confidence、限制说明。

### 落盘检查

确认以下文件已写入/更新：
- `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.{test|spec}.ts`（脚本文件）
- `.e2e-tests/shared/registry/{domain}.yaml`
- `.e2e-tests/shared/registry/index.yaml`
- `.e2e-tests/tasks/{date}-{slug}/task/index.md`

缺失则补写。

## 约束

1. 必须用 subagent 生成
2. 无 prep 不生成
3. 不适合时明确拒绝
4. 注册表必须同步更新
5. 优先复用再新建
6. 资产必须可追溯
7. 沉淀脚本统一进入 shared/automation/，不留 task 目录副本

<IMPORTANT>
业务场景只能通过 UI 验证时，应生成 e2e-script，而不是在 limitations 标注“不支持”然后放弃。
</IMPORTANT>
