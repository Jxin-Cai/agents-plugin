---
name: test-automation-builder
description: 将高价值 E2E 测试路径沉淀为自动化测试资产。支持两种类型：纯 API 脚本（.test.ts）和 E2E 脚本（.spec.ts，含 Playwright UI 验证）。当用户要求"沉淀脚本"，或 test-runner 确认适合自动化时触发。
allowed-tools: Read, Glob, Write, Agent, AskUserQuestion, Bash(npx tsc --noEmit*), Bash(npx tsx*), Bash(npx playwright*)
---

# 自动化测试资产构建器

通过 **Subagent** 将剧本 + 准备方案 + 探索报告转化为可持续回归的自动化脚本。支持两种类型：

**API 脚本 (`type: api-script`)**：
- 直接调 API，查接口返回、查数据库状态
- 零浏览器依赖，`npx tsx` 就能跑
- 适用于：核心操作有完整 API 覆盖的场景

**E2E 脚本 (`type: e2e-script`)**：
- 使用 Playwright Test Runner（`.spec.ts`）
- 混合 API 调用 + UI 交互验证
- 适用于：核心操作必须通过 UI 完成、或验证点依赖 UI 状态的场景
- 数据准备和状态验证仍优先用 API；UI 只用于无 API 替代的操作

两种类型都注册到 registry，都可被 `run-suite` 批量回归。

---

## 前置条件

- 剧本文件和准备方案
- `task/task.md` 与 `task/index.md`
- **Playwright 探索报告**（含 API 调用链摘要）——这是从路径 C 执行中提炼的关键输入；若路径 A/B 已有足够接口知识，也可作为输入
- `references/script-conventions.md` 在 Step 3 确认要生成脚本时才读取

---

## 执行流程

### Step 1: 收集上下文并先检查可复用资产

读取：
- 剧本文件
- 准备方案（TP-{NNN}）
- 当前任务文件与任务索引
- 最近成功报告（如有），**重点提取其中的 API 调用链摘要**
- `.e2e-tests/_shared/helpers/` 中可复用 helper（特别关注 `mock-loader.ts`）
- `.e2e-tests/registry/index.yaml` → 按需读取 `registry/{domain}.yaml`
- `.e2e-tests/asset-catalog.md`（跨 domain 资产发现的主入口）

目标：
- 判断是否已有足够接近的脚本可直接复用或复制微调
- 判断是否已有数据集 / mock / helper 可以直接引用
- 只有确有缺口时才生成新脚本或新共享资产

### Step 2: 判断是否适合自动化

> **注意**：此步骤仅做适配性判断，**不要在此步骤读取** `references/script-conventions.md`。只有判断为“适合”并进入 Step 3 后才读取。

**适合（API 脚本）**：
- 核心操作可通过 API 调用完成（不依赖纯前端交互如拖拽、画布）
- 状态验证可通过接口查询或数据库查询实现
- 准备可重复、数据可编程创建

**适合（E2E 脚本）**：
- 核心操作部分可通过 API，部分必须通过 UI（如文件上传、拖拽、多步表单向导）
- 验证点包含 UI 状态（但仍有 API/Data oracle 层）
- 关键交互无法绕过浏览器

**不适合**：
- 核心业务逻辑在纯前端完成，无对应 API
- 依赖人工视觉判断（如 UI 渲染效果、图表正确性）
- 关键副作用无可查询的接口或数据源

不适合时明确告知用户原因，不硬生成。适合但需要 UI 交互时，使用 `AskUserQuestion` 确认生成 `e2e-script` 类型。

### Step 3: 用 subagent 生成脚本

读取 `references/script-conventions.md`（脚本规范和 subagent prompt 模板）。注册表 schema 见 `skills/e2e/references/registry-conventions.md`。
使用 **Agent 工具** 启动子 agent，按其中的 subagent 模板提供 prompt。

**生成的脚本特征**：

**API 脚本 (`api-script`)**：
- 纯 TypeScript 脚本（`.test.ts`），用 `fetch` / HTTP client 调接口
- 不 import playwright，不操作浏览器
- 可通过 `npx tsx` 直接运行

**E2E 脚本 (`e2e-script`)**：
- Playwright 测试脚本（`.spec.ts`），使用 `test.describe` / `test` 结构
- 数据准备和状态验证优先用 API 调用（`page.request` 或 `beforeAll`）
- UI 交互只用于无 API 替代的操作
- 可通过 `npx playwright test` 运行

**通用**：
- 断言基于接口返回值和数据状态
- 头部元数据明确声明依赖的数据集 / mock / helper / 来源任务

### Step 4: 校验

- 文件存在且头部元数据完整
- 核心断言与 oracle_types 一致
- **API 脚本**：不含任何 Playwright/浏览器依赖
- **E2E 脚本**：Playwright 导入存在，使用 Playwright Test Runner 结构
- 如用户要求可试运行：
  - `api-script`: `npx tsx .e2e-tests/{domain}/automation/ts-{nnn}-*.test.ts`
  - `e2e-script`: `npx playwright test .e2e-tests/{domain}/automation/ts-{nnn}-*.spec.ts`

### Step 5: 更新注册表与资产目录

完成后必须同步更新（registry schema 见 `skills/e2e/references/registry-conventions.md`）：
- `.e2e-tests/registry/{domain}.yaml`（域注册表）
- `.e2e-tests/registry/index.yaml`（更新 `script_count` 和 `last_updated`）
- `.e2e-tests/asset-catalog.md`（跨 domain 可发现，分片策略见 `skills/e2e/references/registry-conventions.md`）
- `.e2e-tests/{domain}/task/index.md`（格式参照 `skills/e2e/references/index-template.md` 的 Stage 6 区块）

至少登记：
- 脚本路径
- 覆盖的业务场景与 case
- 依赖的数据集 / mock / helper
- 来源报告 / 来源任务
- 自动化置信度
- 限制说明
- **`source_paths`**：该脚本覆盖的业务源码路径 glob 列表，从 scan-context 扫描结果（`context/` 文件）中提取（用于 impact-analysis 的变更影响匹配）

### Step 6: 输出资产摘要

展示：
- 脚本路径
- 覆盖的 API 端点和 oracle
- 与探索报告的对应关系
- 复用的资产
- 新增沉淀的资产
- 限制说明（哪些验证点仍需人工确认）

---

## 约束

1. **必须使用 subagent** 生成脚本
2. **没有准备方案不生成**
3. **不适合自动化时要明确拒绝**
4. **注册表必须同步更新**（域注册表 + 全局索引）
5. **API 脚本不得依赖 Playwright；E2E 脚本使用 Playwright Test Runner。类型由 Step 2 决策确定**
6. **优先复用再新建** — 有相近脚本、helper、数据集时，先复用或复制微调
7. **资产必须可追溯** — 脚本依赖了什么、来自哪次任务，必须能从元数据和索引中看出来
8. **mock 配置需可执行** — 如脚本需要 mock，确保使用 mock-loader helper（不存在时一并生成）

<IMPORTANT>
如果某个业务场景只能通过 UI 交互验证（无对应 API），应生成 `e2e-script` 类型，而不是在 limitations 中标注"不支持"然后放弃自动化。
</IMPORTANT>
