---
name: test-automation-builder
description: 将高价值测试路径沉淀为自动化脚本（api-script 或 e2e-script）。当 test-runner Path C 真实浏览器探索成功、需要把自然语言/Markdown 验收步骤导出为 Playwright `.spec.ts` 或复用 API/auth 脚本时使用。
allowed-tools: Read, Glob, Write, Agent, AskUserQuestion, Bash(mkdir*), Bash(npx tsc --noEmit*), Bash(npx tsx*), Bash(npx playwright*)
---

# 自动化测试资产构建器

通过 subagent 将剧本 + prep + 报告 + evidence manifest + console/network artifacts 转化为可回归的自动化脚本。

## 脚本类型

- **api-script**（`.test.ts`）：纯 API，`npx tsx` 执行，禁止 import playwright
- **e2e-script**（`.spec.ts`）：Playwright Test Runner，数据准备用 API，UI 仅用于无 API 替代的操作
- **auth-script**（`.test.ts`）：认证脚本，传入账号密码 → 返回 token/cookie，存放于 `shared/automation/auth/`

## 流程

### Step 1: 收集上下文与资产检索

读取 `.e2e-tests/scenarios/{scenario}/scenario.md`（剧本与 Step Mapping）、当前 run 的 `prep/` 下的方案、`task.md`（Acceptance Source 与 export_intent）、`reports/` 下的报告（重点提取 API 调用链、export recommendation、失败/重试历史）、`evidence/**/evidence-manifest.md`、console/network artifacts、`.e2e-tests/shared/helpers/`、`.e2e-tests/shared/registry/`、`.e2e-tests/shared/asset-catalog.md`、`.e2e-tests/shared/automation/auth/`（认证脚本）。
判断已有脚本/helper/数据集是否可直接复用。

### Step 2: 适配性判断

- 适合 api-script：核心操作有 API + 状态可查询
- 适合 e2e-script：部分操作必须 UI + 验证点包含 UI 状态；Path C 成功跑通且 selector/oracle/prep 可复现时，优先导出 Playwright `.spec.ts`
- 适合 auth-script：登录认证流程，提取 token/cookie
- 不适合：纯视觉判断、缺 oracle、缺稳定选择器、缺可复现 prep、登录/重置链路不可复用 → 明确告知，不硬生成

### Step 3: subagent 生成

> **条件加载**：此时读取 `references/script-conventions.md`（命名与规则）和 `references/script-subagent-prompt.md`（生成 prompt 与导出门禁）。registry schema 见 `skills/e2e/references/registry-conventions.md`。

写入前确保目录存在：
- 业务脚本：`mkdir -p .e2e-tests/shared/automation/{domain}`
- 认证脚本：`mkdir -p .e2e-tests/shared/automation/auth`

通过 Agent 工具启动子 agent 生成脚本：
- 业务脚本写入 `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.{test|spec}.ts`
- 认证脚本写入 `.e2e-tests/shared/automation/auth/login-{env}.test.ts`

生成 e2e-script 时，把 Step Mapping 写入测试结构：每个 test 或 test.step 关联 acceptance step ref，并用报告/evidence 中验证过的稳定定位方式，不把一次性探索痕迹硬编码。

### Step 4: 校验

文件存在 + 元数据完整 + 断言与 oracle_types 一致 + source run/report/evidence 可追溯 + api-script 无 playwright 依赖 / e2e-script 有 Playwright Test 结构和稳定 selector。

### Step 5: 更新注册表与索引

同步更新：
- `.e2e-tests/shared/registry/{domain}.yaml`（脚本条目）
- `.e2e-tests/shared/registry/index.yaml`（全局索引 script_count + last_updated）
- `.e2e-tests/shared/asset-catalog.md`（跨域脚本参考）
- `.e2e-tests/shared/knowledge-index.md`（「自动化脚本」表 + 「认证脚本」表——新增或更新对应行）
- 当前 run 的 `index.md`（已沉淀资产区块）

必须登记：
- 脚本路径、覆盖场景/case、覆盖的 acceptance steps、依赖资产、source_paths、source run/report/evidence、automation_confidence、export_confidence、限制说明
- `execution_mode`：`serial | parallel`
- `parallel_safe`：是否允许与其他脚本并行
- `recommended_workers`：推荐并行度
- `retry_policy`：`none | on-failure-once | flaky-only`
- `trace_policy`：`off | on-failure | on-retry | always`
- `abstraction_mode`：`inline | helper | page-object | keyword`

登记这些字段时不要留空；如果当前脚本仍沿用旧实现方式，也要明确写出现值，而不是省略。判断口径以 `skills/e2e/references/registry-conventions.md` 为准。

### 落盘检查

确认以下文件已写入/更新：
- `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.{test|spec}.ts`（脚本文件）或 `.e2e-tests/shared/automation/auth/login-{env}.test.ts`（认证脚本）
- `.e2e-tests/shared/registry/{domain}.yaml`
- `.e2e-tests/shared/registry/index.yaml`
- `.e2e-tests/shared/knowledge-index.md`（已更新）
- 当前 run 的 `index.md`

缺失则补写。

### 可选：Registry 校验

写入完成后可运行校验确认一致性：
```bash
npx tsx .e2e-tests/shared/helpers/registry-validate.ts
```
校验不通过时用 `--fix` 自动修复计数和 stale 标记。

## 约束

1. 必须用 subagent 生成
2. 无 prep 不生成
3. 不适合时明确拒绝
4. 注册表必须同步更新
5. 优先复用再新建
6. 资产必须可追溯
7. 沉淀脚本统一进入 shared/automation/，不留 run 目录副本
8. 从 Path C 导出时必须保留 report/evidence/console/network 的来源引用
9. 不满足 export gate 时只记录 blocked reason，不生成脆弱脚本

<IMPORTANT>
业务场景只能通过 UI 验证时，应生成 e2e-script，而不是在 limitations 标注"不支持"然后放弃。
</IMPORTANT>
