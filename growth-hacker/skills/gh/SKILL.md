---
name: gh
description: 增长黑客工作台——先装配增长任务，再按意图路由到漏斗优化、增长实验、病毒循环设计、快速体检或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 增长黑客工作台

用户传入的参数：`$ARGUMENTS`

先装配增长任务，再按意图路由到对应 workflow。不是所有需求都需要走完整漏斗 → 实验 → 病毒循环管道。

**入口纪律**：除非用户明确点名 `/funnel-optimization`、`/growth-experiment`、`/viral-loop-design`，或明确要求“只做漏斗 / 只做实验 / 只做病毒 / 只做快速体检”，否则统一先走 `/growth-hacker:gh` 入口。

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
| "漏斗 / 转化率 / 流失" | funnel-only | 调用 `/funnel-optimization $ARGUMENTS` |
| "实验 / 增长假设 / 测试" | experiment-only | 调用 `/growth-experiment $ARGUMENTS` |
| "病毒 / 裂变 / 分享 / 推荐" | viral-only | 调用 `/viral-loop-design $ARGUMENTS` |
| "快速诊断 / 增长体检 / 快扫" | quick-diagnosis | → Step 3 |
| "继续上次增长任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整策略 / 全套" 或复杂需求 | full-strategy | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：funnel-only / experiment-only / viral-only / quick-diagnosis / full-strategy
- `north_star_metric`：北极星指标
- `current_value`：当前值
- `target_value`：目标值
- `aarrr_stage`：核心环节
- `goal`：本次增长目标
- `available_data`：actual / estimate / missing
- `evidence_level`：强 / 中 / 弱
- `reusable_assets`：历史实验 / 漏斗报告 / 推荐机制资产
- `deliverable_mode`：诊断 / 策略 / 实验包 / 全流程
- `workflow_mode`：当前 workflow
- `task_dir`：任务目录简称
- `completed_steps`：已完成阶段
- `artifact_paths`：最近产物路径
- `next_recommended_step`：下一步动作
- `open_questions`：待验证问题
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_growth-hacking/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `funnels/` `experiments/` `viral/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-strategy
task_type: full-strategy
task_dir: {缩写}
north_star_metric:
current_value:
target_value:
aarrr_stage:
goal: {一句话目标}
available_data: missing
evidence_level: weak
reusable_assets: []
deliverable_mode: growth-pack
completed_steps: []
artifact_paths: []
open_questions: []
current_stage: funnel-optimization
next_recommended_step: funnel-optimization
next_step: funnel-optimization
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `funnels/`、`experiments/`、`viral/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 漏斗优化 | `/funnel-optimization $ARGUMENTS` | `funnels/*.md` 存在 | 继续 / 回退 / 结束 |
| 增长实验 | `/growth-experiment $ARGUMENTS` | `experiments/*.md` 存在 | 继续 / 回退 / 结束 |
| 病毒循环设计 | `/viral-loop-design $ARGUMENTS` | `viral/*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速增长体检

编排器内轻量执行，不调用子技能：
1. 优先读取最近任务的 `meta/state.md` 与 `funnels/`、`experiments/`、`viral/` 产物
2. 输出北极星、AARRR 环节、实验速度、单位经济四维速览；无数据必须标注“待验证”
3. 生成精简报告到 `_growth-hacking/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入漏斗 / 深入实验 / 深入病毒循环 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_growth-hacking/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `funnels/`、`experiments/`、`viral/` 产物
3. 恢复时以产物优先于状态文件；无数据阶段要标注待验证；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配增长任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
增长实验必须包含假设 + 指标 + 最小样本量。
漏斗分析必须基于数据而非假设——无数据环节须标注“待验证”。
病毒系数 K 值计算必须标注数据来源和置信度。
所有增长策略必须通过单位经济验证：LTV > 3× CAC，否则标注“需验证经济模型”。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
