---
name: test-automation-builder
description: 将高价值 E2E 测试路径沉淀为纯 API/脚本级自动化测试资产。从 Playwright 探索中提炼接口调用链，生成不依赖浏览器的干净脚本。当用户要求"沉淀脚本"，或 test-runner 确认适合自动化时触发。
allowed-tools: Read, Glob, Write, Agent, Bash(npx tsc --noEmit*), Bash(npx tsx*)
---

# 自动化测试资产构建器

通过 **Subagent** 将剧本 + 准备方案 + Playwright 探索中发现的 API 调用链转化为**纯脚本级自动化测试**——直接调接口、查状态、验证数据，不依赖浏览器。

---

## 核心理念

沉淀的脚本应该：

- **直接调 API**：用 HTTP 请求完成业务操作，不模拟 UI 交互
- **直接验证数据**：查接口返回、查数据库状态，不靠页面截图
- **零浏览器依赖**：`npx tsx` 就能跑，不需要 Playwright runtime

---

## 前置条件

- 剧本文件和准备方案
- **Playwright 探索报告**（含 API 调用链摘要）——这是从路径 C 执行中提炼的关键输入
- `references/script-conventions.md` 在 Step 3 确认要生成脚本时才读取

---

## 执行流程

### Step 1: 收集上下文

读取：
- 剧本文件
- 准备方案（TP-{NNN}）
- 最近成功报告（如有），**重点提取其中的 API 调用链摘要**
- `_shared/helpers/` 中可复用 helper

### Step 2: 判断是否适合自动化

> **注意**：此步骤仅做适配性判断，**不要在此步骤读取** `references/script-conventions.md`。只有判断为"适合"并进入 Step 3 后才读取。

**适合**：
- 核心操作可通过 API 调用完成（不依赖纯前端交互如拖拽、画布）
- 状态验证可通过接口查询或数据库查询实现
- 准备可重复、数据可编程创建

**不适合**：
- 核心业务逻辑在纯前端完成，无对应 API
- 依赖人工视觉判断（如 UI 渲染效果、图表正确性）
- 关键副作用无可查询的接口或数据源

不适合时明确告知用户原因，不硬生成。

### Step 3: 用 subagent 生成脚本

读取 `references/script-conventions.md`（含脚本规范、注册表 schema、subagent prompt 模板）。
使用 **Agent 工具** 启动子 agent，按其中的 subagent 模板提供 prompt。

**生成的脚本特征**：
- 纯 TypeScript 脚本（`.test.ts`），用 `fetch` / HTTP client 调接口
- 不 import playwright，不操作浏览器
- 断言基于接口返回值和数据状态
- 可通过 `npx tsx` 直接运行

### Step 4: 校验

- 文件存在且头部元数据完整
- 核心断言与 oracle_types 一致
- **不含任何 Playwright/浏览器依赖**
- 如用户要求可试运行：`npx tsx .e2e-tests/{domain}/automation/ts-{nnn}-*.test.ts`

### Step 5: 更新注册表

在 `.e2e-tests/registry.yaml` 中新增条目（schema 见 `script-conventions.md`）。

### Step 6: 输出资产摘要

展示：
- 脚本路径
- 覆盖的 API 端点和 oracle
- 与 Playwright 探索报告的对应关系
- 限制说明（哪些验证点仍需人工确认）

---

## 约束

1. **必须使用 subagent** 生成脚本
2. **没有准备方案不生成**
3. **不适合自动化时要明确拒绝**
4. **注册表必须同步更新**
5. **生成的脚本不得依赖 Playwright 或任何浏览器 runtime**

<IMPORTANT>
如果某个业务场景只能通过 UI 交互验证（无对应 API），应在 limitations 中明确标注，而不是生成 Playwright 脚本来凑数。
</IMPORTANT>
