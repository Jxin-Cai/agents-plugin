---
name: fs
description: 反馈综合分析工作台——先装配任务，再按意图路由到反馈收集、情感分析、洞察提取、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 反馈综合分析工作台

用户传入的参数：`$ARGUMENTS`

先装配反馈分析任务，再带他进入对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：仅当用户明确点名子 skill 或明确要求“只做反馈收集 / 只做情感分析 / 只做洞察提取 / 只做快速检查”时，才直达对应阶段；否则都先走 `/feedback-synthesizer:fs` 入口完成任务装配。

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
| "收集 / 采集 / 汇总反馈" | collect-only | 调用 `/feedback-collection $ARGUMENTS` |
| "情感 / 情绪 / 正负面" | sentiment-only | 调用 `/sentiment-analysis $ARGUMENTS` |
| "洞察 / 提炼 / 趋势" | insight-only | 调用 `/insight-extraction $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "继续上次反馈任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整分析 / 全套" 或复杂需求 | full-synthesis | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：collect-only / sentiment-only / insight-only / quick-scan / full-synthesis
- `workflow`：当前 workflow
- `task_slug`：任务简称
- `product_scope`：产品 / 版本 / 渠道范围
- `time_range`：时间窗口
- `user_segments`：目标用户分群
- `data_sources`：评价 / 工单 / 社媒 / 调研 / NPS / CSAT
- `decision_goal`：本次分析要支撑的决策
- `current_stage`：当前阶段
- `next_step`：下一步动作
- `artifacts_expected`：预期产物
- `artifacts_found`：已发现产物
- `updated_at`：最近更新时间

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_feedback/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `raw-feedback/` `analysis/` `insights/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-synthesis
task_type: full-synthesis
task_slug: {缩写}
product_scope: {产品/版本/渠道}
time_range: {时间范围}
user_segments: []
data_sources: []
decision_goal: {一句话决策目标}
current_stage: feedback-collection
completed_steps: []
next_step: feedback-collection
artifacts_expected: [raw-feedback, analysis, insights]
artifacts_found: []
updated_at: {YYYY-MM-DD}
```

5. 扫描 `raw-feedback/`、`analysis/`、`insights/` 中已有产物，检查接续点（产物优先于状态文件）
6. 重新 Read `meta/state.md` 交叉验证，若 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 反馈收集 | `/feedback-collection $ARGUMENTS` | `raw-feedback/feedback-*.md` 存在 | 继续 / 回退 / 结束 |
| 情感分析 | `/sentiment-analysis $ARGUMENTS` | `analysis/sentiment-*.md` 存在 | 继续 / 回退 / 结束 |
| 洞察提取 | `/insight-extraction $ARGUMENTS` | `insights/insights-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段完成后：
1. Read 子技能产出文件，Write 不超过 20 行的摘要到 `meta/{stage}-summary.md`
2. 更新 `meta/state.md` 的 `completed_steps`、`next_step`、`artifacts_found`、`updated_at`
3. 使用 `AskUserQuestion` 展示选项：继续下一阶段 / 回退重做 / 结束

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

使用 Glob 扫描 `_feedback/` 下最近的工作目录（如无则请用户提供数据源），按以下维度执行速览：

| 维度 | 检查动作 | 输出 |
|------|---------|------|
| 渠道覆盖 | 统计反馈来源渠道数和各渠道占比 | 单渠道偏差预警 |
| 情感分布 | 抽样 10-15 条反馈快速标注正/负/中 | 整体情感倾向 |
| 高频主题 | 识别出现 ≥3 次的关键词或主题 | Top 3 高频主题 |
| 紧急信号 | 检查是否有功能故障、数据丢失等严重负面 | 红旗标记 |

将速览结果 Write 到 `_feedback/quick-scan-{日期}.md`（渠道覆盖 + 情感分布 + Top 主题 + 紧急信号 + 建议下一步）。

使用 `AskUserQuestion` 展示速览结果并提供选项：深入某个维度 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_feedback/` 下未完成目录
2. 先 Read `meta/state.md`，再检查 `raw-feedback/`、`analysis/`、`insights/` 实物产物
3. 恢复以 `raw-feedback / analysis / insights` 实物优先，state 只做索引
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配反馈任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
洞察必须有原始反馈引用支撑，不可凭空推断。
情感分析必须附带典型引言。
数据量不足时必须声明置信度限制。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
