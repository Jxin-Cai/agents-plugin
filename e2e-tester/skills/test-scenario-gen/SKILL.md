---
name: test-scenario-gen
description: 基于 BDD + 风险 + Oracle 模型生成测试剧本
allowed-tools: Read, Glob, Write, AskUserQuestion
---

# 测试剧本生成器

基于任务文件和上下文生成 BDD 剧本。剧本不是步骤清单，而是业务场景 × case × oracle × 证据要求的组合。

## 前置条件

1. `task/task.md` 和上下文摘要（除非用户跳过扫描）
2. 读取 `task/index.md` 识别已挂载的资产
3. 检索 `registry/index.yaml` 避免编号冲突，检索 `asset-catalog.md` 寻找可复用资产

> 若 `task/task.md` 不存在，提示用户先通过 `/e2e` 入口完成任务装配，不直接生成空洞剧本。

## 流程

### Step 1: 规划剧本列表

- 一个业务场景一个剧本（TS-{NNN}-{slug}.md）
- 每个剧本内多个 case：Happy Path（必须）、Key Exception（必须）、Boundary/Permission/Async/Idempotency（按需）
- 已有剧本时先判断：沿用 / 追加 case / 重排 / 新增
- `AskUserQuestion` 确认规划

### Step 2: 设计 case oracle

每个 case 回答：为什么测、通过看什么信号、失败最担心什么、需要什么准备、能否复用资产、是否适合自动化。
只有 UI 信号没有业务结果信号 → 重新设计。

### Step 3: 生成剧本

**条件加载**：读取 `references/scenario-template.md`。涉及 mock 时才读 `references/mock-strategy.md`；涉及契约/故障注入时才读 `references/mock-strategy-advanced.md`。

Frontmatter 必含：goal、risk_level、persona、business_scenario、case_count、out_of_scope、prep_ref、oracle_types、dependencies。

### Step 4-5: 写入文件、更新索引、用户确认

写入 `scenarios/TS-{NNN}-{slug}.md`，在 index.md 登记，`AskUserQuestion` 确认。

## 约束

1. 一剧本一业务场景，不混装不相关功能
2. 严禁只写 UI——关键结果不得只用 UI 文案证明
3. case 必须可单独判 PASS/FAIL
4. 编号全局唯一
5. 优先复用资产
6. 支持中断接续

<IMPORTANT>
剧本无法回答"业务场景是什么""怎么证明通过""需要什么准备"时，不能进入执行。
</IMPORTANT>
