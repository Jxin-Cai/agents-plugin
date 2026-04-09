---
name: test-automation-builder
description: 将高价值 E2E 测试路径沉淀为可复用的 Playwright 自动化测试脚本。当用户要求"沉淀脚本"，或 test-runner 确认适合自动化时触发。
allowed-tools: Read, Glob, Write, Agent, Bash(npx tsc --noEmit*)
---

# 自动化测试资产构建器

通过 **Subagent** 将剧本 + 准备方案 + 执行报告转化为可长期复用的 Playwright TypeScript 自动化脚本。

---

## 前置条件

读取剧本文件和准备方案。`references/script-conventions.md` 在 Step 3 确认要生成脚本时才读取。

---

## 执行流程

### Step 1: 收集上下文

读取：
- 剧本文件
- 准备方案（TP-{NNN}）
- 最近成功报告（如有）
- `_shared/helpers/` 中可复用 helper

### Step 2: 判断是否适合自动化

**适合**：准备可重复、oracle 可稳定验证、交互稳定、定位器可持续
**不适合**：依赖人工判断、关键副作用不可稳定观测、准备不可复现

不适合时明确告知用户原因，不硬生成。

### Step 3: 用 subagent 生成脚本

读取 `references/script-conventions.md`（含脚本规范、注册表 schema、subagent prompt 模板）。
使用 **Agent 工具** 启动子 agent，按其中的 subagent 模板提供 prompt。

### Step 4: 校验

- 文件存在且头部元数据完整
- 核心断言与 oracle_types 一致
- 如用户要求可试运行

### Step 5: 更新注册表

在 `.e2e-tests/registry.yaml` 中新增条目（schema 见 `script-conventions.md`）。

### Step 6: 输出资产摘要

展示脚本路径、覆盖的 oracle、限制说明。

---

## 约束

1. **必须使用 subagent** 生成脚本
2. **没有准备方案不生成**
3. **不适合自动化时要明确拒绝**
4. **注册表必须同步更新**

<IMPORTANT>
沉淀的是带适用边界和限制说明的资产，不是翻译一次执行记录。
</IMPORTANT>
