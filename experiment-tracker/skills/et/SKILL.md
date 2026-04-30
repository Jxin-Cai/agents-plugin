---
name: et
description: 实验跟踪工作台——先装配任务，再按意图路由到 A/B 测试设计、指标定义、结果分析、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 实验跟踪工作台

用户传入的参数：`$ARGUMENTS`

先装配实验任务，再带他进入对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：除非用户明确点名 `/ab-test-design`、`/metrics-definition`、`/results-analysis`，或明确要求“只做实验设计 / 只做指标定义 / 只做结果分析 / 只做快速检查”，否则都先走 `/experiment-tracker:et` 入口。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "A/B 测试 / 实验设计 / 假设 / 对照组 / 实验组 / 变体 / 分组" | design-only | 调用 `/ab-test-design $ARGUMENTS` |
| "指标 / KPI / 北极星 / 转化率 / CTR / 留存 / 口径" | metrics-only | 调用 `/metrics-definition $ARGUMENTS` |
| "结果 / 分析 / 显著性 / p值 / 置信区间 / 推全 / 回滚" | analysis-only | 调用 `/results-analysis $ARGUMENTS` |
| "快速检查 / 实验状态 / 进度" | quick-check | → Step 3 |
| "继续上次实验任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整流程 / 全套" 或复杂需求 | full-workflow | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：design-only / metrics-only / analysis-only / quick-check / full-workflow
- `workflow`：当前 workflow
- `experiment_slug`：实验简称
- `objective`：实验目标
- `primary_metric`：核心指标
- `guardrails`：护栏指标
- `data_status`：无数据 / 已有基线 / 实验中 / 已收数
- `required_artifacts`：预期产物
- `next_action`：下一步动作
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_experiments/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `designs/` `metrics/` `results/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-workflow
task_type: full-workflow
experiment_slug: {缩写}
objective: {一句话目标}
primary_metric: 
guardrails: []
data_status: baseline-ready
required_artifacts: [designs, metrics, results]
current_stage: ab-test-design
completed_steps: []
next_step: ab-test-design
next_action: 完成实验设计并预注册
```

5. 扫描已有目录，检查 `designs/`、`metrics/`、`results/` 产物，产物优先于状态文件
6. 使用 `AskUserQuestion` 确认从哪里开始

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| A/B 测试设计 | `/ab-test-design $ARGUMENTS` | `designs/*.md` | 继续 / 回退 / 结束 |
| 指标定义 | `/metrics-definition $ARGUMENTS` | `metrics/*.md` | 继续 / 回退 / 结束 |
| 结果分析 | `/results-analysis $ARGUMENTS` | `results/*.md` | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能。用 Glob 扫描 `_experiments/` 目录，按以下维度生成速览报告：

| 维度 | 检查动作 | 输出 |
|------|---------|------|
| 实验总览 | 列出所有实验目录及创建日期 | 实验列表 + 状态（进行中/已完成） |
| 设计完整性 | 检查 `designs/` 是否有设计文件 | 有/缺失 |
| 指标定义 | 检查 `metrics/` 是否有指标文件 | 有/缺失 |
| 结果分析 | 检查 `results/` 是否有分析文件 | 有/缺失 |
| 进度状态 | Read `meta/state.md` 获取 next_step | 当前阶段 + 下一步 |

将速览结果写入 `_experiments/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_experiments/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `designs/`、`metrics/`、`results/` 产物
3. 恢复时以 `designs / metrics / results` 实物优先
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配实验任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
A/B 测试必须包含样本量计算和统计显著性标准。
结果分析必须区分统计显著与业务显著。
不可在实验未达到最小样本量时下结论。
所有实验必须执行 SRM（Sample Ratio Mismatch）检查，发现 SRM 必须暂停分析排查原因。
完整流程中，实验假设和分析计划必须在数据收集前预注册（写入 designs/ 目录），分析阶段必须严格对照预注册计划执行，禁止事后修改假设或选择性报告。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
