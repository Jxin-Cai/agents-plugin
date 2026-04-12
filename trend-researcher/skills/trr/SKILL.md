---
name: trr
description: 趋势研究工作台——按意图路由到市场分析、竞争格局、技术趋势报告或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 趋势研究工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "市场 / 行业 / 规模" | market-only | 调用 `/market-analysis $ARGUMENTS` |
| "竞品 / 竞争 / 格局" | competitive-only | 调用 `/competitive-landscape $ARGUMENTS` |
| "技术趋势 / 新技术 / 技术雷达" | tech-only | 调用 `/tech-trend-report $ARGUMENTS` |
| "快速概览 / 速查" | quick-scan | → Step 3 |
| "完整研究 / 全套 或复杂需求" | full-research | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅市场 
- 仅竞品 
- 仅技术趋势 
- 快速趋势研究检查
- 完整趋势研究流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_trend-research/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

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

编排器内轻量执行，不调用子技能。基于用户提供的信息和对话上下文，逐项输出以下五个维度，每个维度完成后展示再继续下一个：

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
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
市场数据必须标注来源和时间。
竞品分析必须基于公开可验证信息。
技术趋势不可混淆「热度」和「成熟度」。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
