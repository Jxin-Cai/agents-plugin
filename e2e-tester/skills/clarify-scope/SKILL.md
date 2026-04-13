---
name: clarify-scope
description: QA 任务装配器——识别工作类型，澄清目标、风险、边界、证据要求，决定 workflow
allowed-tools: Read, Write, Glob, AskUserQuestion
---

# QA 任务装配与澄清

> **条件加载**：进入装配细化前读取 `references/qa-task-assembly-dimensions.md` 和 `references/workflow-decision-table.md`。

---

## 执行流程

### Step 0: 先扫资产，再决定问什么

扫描 `.e2e-tests/asset-catalog.md`、`.e2e-tests/registry/`、`.e2e-tests/_shared/`、`.e2e-tests/{domain}/task/task.md`（如存在）。
识别可复用资产和可接续任务，只追问缺口。

### Step 1: 装配任务类型与目标

用 `AskUserQuestion` 收集（可分多轮，允许 Other + multiSelect）：

| 必收集 | 说明 |
|--------|------|
| 任务类型 | 见 `references/qa-task-assembly-dimensions.md` 中的 task_type 枚举 |
| 目标问题 | 这次最重要的问题是什么 |
| 触发原因 | 发布前 / 缺陷 / 变更 / 巡检 |
| 成功判据 | 具体到业务承诺或放行条件 |
| 不可接受结果 | 一出现就判失败的信号 |
| 交付物 | 报告 / 证据 / 脚本 |
| 证据级别 | light / standard / strict（默认建议：release-gate→strict，design-lite→light，其他→standard） |

### Step 2: 边界、角色、依赖

继续追问：测试边界、用户角色/权限、前置数据状态、环境/时间窗、外部副作用、异步链路、依赖策略（real/mock/fixture）。

按场景 profile 追问最少必要信息：
- `release-readiness`：发布范围、阻断项、最小验证集
- `bug-repro`：复现条件、波动性、最小证据链
- 专项验证：围绕核心风险点追问

### Step 3: 决定 workflow

基于已有信息和决策表选择 workflow。必须说明依据。
若已有资产足够明确，建议轻 workflow 而非默认 design-full。

### Step 4: 生成任务文件

写入 `.e2e-tests/{domain}/task/task.md`：

```markdown
# 当前 QA 任务

## 任务装配卡
- task_type / workflow / 触发原因 / 目标 / 交付物 / evidence_level

## 基本信息
- 被测对象 / 风险等级 / 入口 / 环境

## 成功判据 / 不可接受结果 / 边界
## 角色与权限 / 前置状态
## 依赖与策略（表格）
## Oracle Profile（UI/API/Data/SideEffect/Async/Idempotency）
## 候选可复用资产
## Workflow 决策依据
## 待补充信息
```

已有文件时补充修订，不无条件覆盖。

### Step 5: 更新索引并确认

在 `.e2e-tests/{domain}/task/index.md` 登记 task_type、workflow、Intent Assembly Card、Workflow Decision Log。
`AskUserQuestion` 确认后结束。

### 落盘检查

确认以下文件已写入：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`

缺失则补写。

---

## 约束

1. 必须产出 `.e2e-tests/{domain}/task/task.md`，不是口头摘要
2. 先装配工作类型，再设计测试——不默认进新功能六阶段
3. 无成功判据和不可接受结果 → 不进入后续 workflow
4. 角色、状态、边界、依赖策略必须明确
5. 优先复用，只追问缺口
6. workflow 决策要可追溯
7. 支持中断接续
