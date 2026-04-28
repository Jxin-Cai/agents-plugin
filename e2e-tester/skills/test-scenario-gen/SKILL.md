---
name: test-scenario-gen
description: 基于 BDD + 风险 + Oracle 模型生成测试剧本
allowed-tools: Read, Glob, Write, AskUserQuestion
---

# 测试剧本生成器

基于任务文件和上下文生成 BDD 剧本。剧本不是步骤清单，而是业务场景 × case × oracle × 证据要求的组合。

## 前置条件

1. 当前 run 的 `task.md` 和上下文摘要（除非用户跳过扫描）
2. 读取当前 run 的 `index.md` 识别已挂载的资产
3. 检索 `.e2e-tests/shared/registry/index.yaml` 避免编号冲突，检索 `.e2e-tests/shared/asset-catalog.md` 寻找可复用资产
4. 读取已有的 `.e2e-tests/scenarios/{scenario}/scenario.md`（如存在）

> 若当前 run 的 `task.md` 不存在，提示用户先通过 `/e2e` 入口完成任务装配，不直接生成空洞剧本。

## 流程

### Step 1: 规划 case 列表

- 剧本以场景为单位：`.e2e-tests/scenarios/{scenario}/scenario.md`
- 每个剧本内多个 case：Happy Path（必须）、Key Exception（必须）、Boundary/Permission/Async/Idempotency（按需）
- 若 `task.md` 含 Acceptance Source，先把原始验收步骤拆成 step refs，再映射到 case、oracle 和证据要求；不要把 checklist 原样当作 case
- **已有 scenario.md 时先判断**：沿用现有 case / 追加新 case / 调整 case / 全新设计
- `AskUserQuestion` 确认规划

### Step 2: 设计 case oracle

每个 case 回答：为什么测、通过看什么信号、失败最担心什么、需要什么准备、能否复用资产、是否适合自动化、覆盖哪些 acceptance step refs。
只有 UI 信号没有业务结果信号 → 重新设计。

### Step 3: 生成剧本

**条件加载**：读取 `references/scenario-template.md`。涉及 mock 时才读 `references/mock-strategy.md`；涉及契约/故障注入时才读 `references/mock-strategy-advanced.md`。

Frontmatter 必含：goal、risk_level、persona、business_scenario、case_count、out_of_scope、prep_ref、oracle_types、dependencies。若存在验收来源，还要写入 `acceptance_source_type`、`acceptance_step_count`。

### Step 4: 写入文件

写入 `.e2e-tests/scenarios/{scenario}/scenario.md`。
- **已有 scenario.md 时**：在现有 case 池基础上追加/修改，不推倒重来
- **新建时**：完整生成

### Step 5: 更新索引并确认

在当前 run 的 `index.md` 登记剧本信息。`AskUserQuestion` 确认。

### 落盘检查

确认以下文件已写入：
- `.e2e-tests/scenarios/{scenario}/scenario.md`
- 当前 run 的 `index.md`（已更新）

缺失则补写。

## 约束

1. 一剧本一业务场景，不混装不相关功能
2. 严禁只写 UI——关键结果不得只用 UI 文案证明
3. case 必须可单独判 PASS/FAIL
4. 编号全局唯一
5. 优先复用资产
6. 支持中断接续
7. Acceptance Source 必须映射到 case/oracle/evidence；无法判定 oracle 的步骤标记为待澄清

<IMPORTANT>
剧本无法回答"业务场景是什么""怎么证明通过""需要什么准备"时，不能进入执行。
</IMPORTANT>
