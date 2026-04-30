---
name: woa
description: 微信公众号运营工作台——先装配公众号任务，再按意图路由到内容策略、文章创作、发布到微信、粉丝分析、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 微信公众号运营工作台

用户传入的参数：`$ARGUMENTS`

先装配公众号运营任务，再按意图路由到对应 workflow。不是所有需求都需要走完整内容策略 → 文章创作 → 发布 → 分析管道。

**入口纪律**：除非用户明确点名 `/content-strategy`、`/article-creation`、`/publish-to-wechat`、`/subscriber-analytics`，或明确要求“只做策略 / 只写文章 / 只做发布 / 只做分析 / 只做快速检查”，否则统一先走 `/wechat-official-account:woa` 入口。

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
| "内容策略 / 选题 / 排期" | strategy-only | 调用 `/content-strategy $ARGUMENTS` |
| "文章 / 创作 / 写作" | article-only | 调用 `/article-creation $ARGUMENTS` |
| "发布 / 推送 / 排版" | publish-only | 调用 `/publish-to-wechat $ARGUMENTS` |
| "分析 / 数据 / 粉丝" | analytics-only | 调用 `/subscriber-analytics $ARGUMENTS` |
| "快速检查 / 概览 / 现状" | quick-scan | → Step 3 |
| "继续上次公众号任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整流程 / 全套" 或复杂需求 | full-workflow | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `workflow`：当前 workflow
- `task_slug`：任务简称
- `account_scope`：账号或栏目范围
- `goal`：本次运营目标
- `deliverable_type`：策略 / 文章 / 发布 / 分析 / 全流程 / 快检
- `source_materials`：已有素材来源
- `publish_window`：发布时间窗
- `data_window`：分析时间窗
- `constraints`：平台 / 人力 / 风格 / 合规约束
- `confirm_gate`：是否需要发布前二次确认
- `artifact_paths`：最近产物
- `next_step`：下一步动作
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_wechat-oa/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `strategy/` `articles/` `analytics/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-workflow
task_slug: {缩写}
account_scope: default
goal: {一句话目标}
deliverable_type: wechat-oa-pack
source_materials: []
publish_window: unknown
data_window: unknown
constraints: []
confirm_gate: required
artifact_paths: []
current_stage: content-strategy
completed_steps: []
next_step: content-strategy
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `strategy/`、`articles/`、`analytics/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 内容策略 | `/content-strategy $ARGUMENTS` | `strategy/*.md` 存在 | 继续 / 回退 / 结束 |
| 文章创作 | `/article-creation $ARGUMENTS` | `articles/article-*.md` 存在 | 继续 / 回退 / 结束 |
| 发布到微信 | `/publish-to-wechat $ARGUMENTS` | `articles/publish-report-*.md` 存在 | 继续 / 回退 / 结束 |
| 粉丝分析 | `/subscriber-analytics $ARGUMENTS` | `analytics/*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能：
1. 读取最近任务的 `meta/state.md` 与 `strategy/`、`articles/`、`analytics/` 产物
2. 输出最近策略、文章库存、发布状态、分析状态与最近时间窗
3. 若缺关键数据，只标注缺口与建议动作，不臆造分析结论
4. 将结果汇总到 `_wechat-oa/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入策略 / 深入文章 / 深入发布 / 深入分析 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_wechat-oa/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `strategy/`、`articles/`、`analytics/` 产物
3. 恢复时以产物优先于状态文件；发布前必须再次确认；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配公众号任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
内容策略必须考虑平台规则和账号定位。
文章创作必须注明引用来源。
数据分析必须标注时间窗口和样本来源。
发布阶段必须在用户确认后执行，不可默认发布。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
