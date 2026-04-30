---
name: tra
description: 测试结果分析工作台——先装配任务，再按意图路由到覆盖率分析、失败分析、质量报告、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 测试结果分析工作台

用户传入的参数：`$ARGUMENTS`

先装配测试分析任务，再带他进入对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：自然语言测试分析请求默认先走 `/test-results-analyzer:tra`，除非用户明确点名子 skill（仅覆盖率 / 仅失败 / 仅报告）或明确说明只做单项。

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
| "覆盖率 / coverage / 未覆盖" | coverage-only | 调用 `/coverage-analysis $ARGUMENTS` |
| "失败 / 错误 / 根因" | failure-only | 调用 `/failure-analysis $ARGUMENTS` |
| "报告 / 质量 / 趋势" | report-only | 调用 `/quality-report $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "继续上次测试分析任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整分析 / 全套" 或复杂需求 | full-analysis | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：coverage-only / failure-only / report-only / quick-scan / full-analysis
- `workflow_mode`：当前 workflow
- `entry_intent`：用户原话
- `analysis_scope`：模块 / 服务 / 流水线
- `data_sources`：coverage_report / failure_log / historical_report
- `baseline_window`：对比窗口，如 `last_3_runs`
- `quality_gate_profile`：default / strict / custom
- `deliverable`：覆盖率结论 / 根因归类 / 质量报告
- `current_stage`：当前阶段
- `completed_steps`：已完成阶段
- `next_step`：下一步动作
- `last_updated`：最近更新时间

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 使用 Bash(mkdir*) 创建 `_test-analysis/{当前日期}-{缩写}/` 及子目录 `context/`、`meta/`、`coverage/`、`failures/`、`reports/`
4. 使用 Write 初始化 `meta/state.md`：
   ```
   workflow_mode: full-analysis
   task_type: full-analysis
   entry_intent: {用户原话}
   analysis_scope: {模块/服务/流水线}
   data_sources: []
   baseline_window: last_3_runs
   quality_gate_profile: default
   deliverable: quality-pack
   current_stage: coverage-analysis
   completed_steps: []
   next_step: coverage-analysis
   last_updated: {YYYY-MM-DD}
   ```
5. 使用 Glob 搜索 `coverage/*.md`、`failures/*.md`、`reports/*.md`；若某阶段产出文件已存在则标记该阶段为已完成；再 Read `meta/state.md` 交叉验证，产出文件与 state.md 冲突时以产出文件为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志（产出文件） | 门控 |
|------|------|---------|------|
| 覆盖率分析 | `/coverage-analysis $ARGUMENTS` | `{工作目录}/coverage/coverage-{日期}.md` 存在 | 使用 AskUserQuestion：继续 / 回退 / 结束 |
| 失败分析 | `/failure-analysis $ARGUMENTS` | `{工作目录}/failures/failure-{日期}.md` 存在 | 使用 AskUserQuestion：继续 / 回退 / 结束 |
| 质量报告 | `/quality-report $ARGUMENTS` | `{工作目录}/reports/quality-report-{日期}.md` 存在 | 使用 AskUserQuestion：继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

使用 `AskUserQuestion` 引导用户提供测试覆盖率报告和测试结果报告（文件路径或口述关键数据）。收到数据后，在编排器内直接执行以下速览，不调用子技能：

| 维度 | 检查项 | 数据来源 |
|------|--------|---------|
| 覆盖率 | 整体行覆盖率、分支覆盖率，对照 80%/70% 基准 | 用户提供的覆盖率报告 |
| 失败率 | 失败总数、通过率，是否 >= 95% | 用户提供的测试报告 |
| Flaky | Flaky 测试数量和占比，是否 < 1% | 用户提供的重复运行数据 |
| 趋势 | 与上次数据对比，标注上升/下降/持平 | `_test-analysis/` 下已有产出 |

将速览结果写入 `_test-analysis/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 使用 Glob 搜索 `_test-analysis/*/meta/state.md`，对每个匹配目录 Read 其 `state.md`
2. 对每个目录，使用 Glob 检查 `coverage/*.md`、`failures/*.md`、`reports/*.md` 是否存在，以产出文件实际存在情况确定已完成阶段
3. 恢复顺序固定为：产物文件 > state.md；“无 state 但有产物”也算可恢复任务
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配测试分析任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
覆盖率分析必须区分行覆盖和分支覆盖。
失败分析必须有根因分类（代码/环境/数据/flaky）。
不可仅看覆盖率数字，需分析覆盖质量。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
