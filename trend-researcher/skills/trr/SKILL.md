---
name: trr
description: 趋势研究工作台——先装配任务，再按意图路由到市场分析、竞争格局、技术趋势报告、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 趋势研究工作台

用户传入的参数：`$ARGUMENTS`

先装配趋势研究任务，再带他进入对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：除非用户明确点名 `/market-analysis`、`/competitive-landscape`、`/tech-trend-report`，或明确要求“只做市场 / 只做竞品 / 只做技术趋势 / 只做快速概览”，否则统一先走 `/trend-researcher:trr` 入口。

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
| "市场 / 行业 / 规模" | market-only | 调用 `/market-analysis $ARGUMENTS` |
| "竞品 / 竞争 / 格局" | competitive-only | 调用 `/competitive-landscape $ARGUMENTS` |
| "技术趋势 / 新技术 / 技术雷达" | tech-only | 调用 `/tech-trend-report $ARGUMENTS` |
| "快速概览 / 速查" | quick-scan | → Step 3 |
| "继续上次趋势任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整研究 / 全套" 或复杂需求 | full-research | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `topic`：研究主题
- `domain`：所属行业 / 赛道
- `goal`：本次研究目标
- `scope`：地域 / 细分市场 / 时间窗
- `deliverable`：市场 / 竞品 / 技术 / 速览 / 完整包
- `evidence_mode`：仅本地 / 可联网
- `resume_target`：自动恢复 / 用户指定阶段
- `current_stage`：当前阶段
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_trend-research/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `market/` `competitive/` `trends/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-research
topic: {研究主题}
domain: {行业/赛道}
goal: {一句话目标}
scope: {地域/时间窗}
deliverable: research-pack
evidence_mode: local-first
resume_target: auto
current_stage: market-analysis
completed_steps: []
next_step: market-analysis
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查接续点（产物优先于状态文件）
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志（Glob 检查） | 门控 |
|------|------|----------------------|------|
| 市场分析 | `/market-analysis $ARGUMENTS` | `market/market-analysis-*.md` 存在 | 继续 / 回退 / 结束 |
| 竞争格局 | `/competitive-landscape $ARGUMENTS` | `competitive/competitive-landscape-*.md` 存在 | 继续 / 回退 / 结束 |
| 技术趋势报告 | `/tech-trend-report $ARGUMENTS` | `trends/tech-trend-report-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能。基于用户提供的信息和对话上下文，逐项输出以下五个维度：

| 维度 | 输出要求 | 篇幅 |
|------|---------|------|
| 市场概况 | 市场规模量级 + 近 3 年增长率 + 生命周期阶段判断，标注数据来源 | 2-3 句 |
| 竞争格局速览 | 前 3 名玩家名称 + 各自一句话定位 + 集中度判断（高/中/低） | 3-5 行 |
| 关键技术趋势 | 3-5 个技术趋势 + 各自 Hype Cycle 阶段（萌芽/膨胀/低谷/爬升/高峰） | 列表 |
| 风险与机会 | Top 2 风险 + Top 2 机会，每条一句话说明 | 4 行 |
| 建议下一步 | 基于以上速览，建议优先深入哪个维度及原因 | 1-2 句 |

全部维度完成后，将速览报告保存到 `_trend-research/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_trend-research/` 下未完成目录
2. 先看产物，再 Read `meta/state.md` 校验
3. 恢复时优先依据产物、其次状态、最后才参考对话记忆
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配趋势任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
市场数据必须标注来源和时间。
竞品分析必须基于公开可验证信息。
技术趋势不可混淆「热度」和「成熟度」。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
