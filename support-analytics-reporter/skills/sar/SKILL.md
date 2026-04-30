---
name: sar
description: 数据分析报告工作台——先装配分析任务，再按意图路由到高管仪表盘、客户分群、营销归因、快速概览或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 数据分析报告工作台

用户传入的参数：`$ARGUMENTS`

先装配分析任务，再按意图路由到对应 workflow。不是所有需求都需要走完整仪表盘 → 分群 → 归因管道。

**入口纪律**：除非用户明确点名 `/executive-dashboard`、`/customer-segmentation`、`/marketing-attribution`，或明确要求“只做仪表盘 / 只做分群 / 只做归因 / 只做快速概览”，否则统一先走 `/support-analytics-reporter:sar` 入口。

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
| "仪表盘 / dashboard / 高管" | dashboard-only | 调用 `/executive-dashboard $ARGUMENTS` |
| "分群 / 细分 / 画像" | segmentation-only | 调用 `/customer-segmentation $ARGUMENTS` |
| "归因 / 渠道 / attribution" | attribution-only | 调用 `/marketing-attribution $ARGUMENTS` |
| "快速概览 / 数据速查 / 快扫" | quick-scan | → Step 3 |
| "继续上次分析任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整分析 / 全套" 或复杂需求 | full-analysis | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：dashboard-only / segmentation-only / attribution-only / quick-scan / full-analysis
- `workflow`：当前 workflow
- `task_slug`：任务简称
- `task_dir`：任务目录简称
- `resume_mode`：自动恢复 / 指定阶段 / 重新开始
- `business_question`：要回答的业务问题
- `audience`：报告面向对象
- `time_range`：分析时间窗
- `grain`：日 / 周 / 月 / 用户级 / 会话级
- `delivery_mode`：仪表盘 / 报告 / 速览 / 完整分析包
- `data_sources`：数据来源列表
- `reliability_level`：L1-L4
- `metric_scope`：指标范围
- `segment_dimensions`：分群维度
- `attribution_model`：归因模型
- `confidence_note`：置信度说明
- `artifact_paths`：最近产物
- `next_step`：下一步动作
- `state_history`：状态历史摘要
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_analytics/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `dashboards/` `segmentation/` `attribution/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-analysis
task_type: full-analysis
task_slug: {缩写}
task_dir: {缩写}
resume_mode: auto
business_question: {一句话目标}
audience: unknown
time_range: unknown
grain: unknown
delivery_mode: analytics-pack
data_sources: []
reliability_level: L4
metric_scope: []
segment_dimensions: []
attribution_model: unknown
confidence_note: pending
artifact_paths: []
state_history: []
current_stage: executive-dashboard
completed_steps: []
next_step: executive-dashboard
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `dashboards/`、`segmentation/`、`attribution/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 高管仪表盘 | `/executive-dashboard $ARGUMENTS` | `dashboards/*` 存在 | 继续 / 回退 / 结束 |
| 客户分群 | `/customer-segmentation $ARGUMENTS` | `segmentation/*` 存在 | 继续 / 回退 / 结束 |
| 营销归因 | `/marketing-attribution $ARGUMENTS` | `attribution/*` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能：
1. 优先读取最近任务的 `meta/state.md` 与 `dashboards/`、`segmentation/`、`attribution/` 产物
2. 输出营收概况、用户健康度、渠道效率、客户结构四维速览
3. 若数据不足，只生成带来源、时间范围与置信度说明的速览卡，不臆造结论
4. 将结果写入 `_analytics/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入仪表盘 / 深入分群 / 深入归因 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_analytics/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `dashboards/`、`segmentation/`、`attribution/` 产物
3. 恢复时以产物优先于状态文件；所有恢复结论都要标注数据来源、时间范围和置信说明
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配分析任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
所有数据结论必须标注数据来源和时间范围。
归因模型必须声明假设和局限性。
不可用相关性暗示因果性。
样本量不足时（n<30 或统计功效<0.8），必须标注置信度局限。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
