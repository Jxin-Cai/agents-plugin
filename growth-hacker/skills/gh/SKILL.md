---
name: gh
description: 增长黑客工作台——按意图路由到漏斗优化、增长实验、病毒循环设计或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 增长黑客工作台

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
| "漏斗 / 转化率 / 流失" | funnel-only | 调用 `/funnel-optimization $ARGUMENTS` |
| "实验 / 增长假设 / 测试" | experiment-only | 调用 `/growth-experiment $ARGUMENTS` |
| "病毒 / 裂变 / 分享 / 推荐" | viral-only | 调用 `/viral-loop-design $ARGUMENTS` |
| "快速诊断 / 增长体检" | quick-diagnosis | → Step 3 |
| "完整策略 / 全套 或复杂需求" | full-strategy | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅漏斗 
- 仅实验 
- 仅病毒 
- 快速增长策略检查
- 完整增长策略流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_growth-hacking/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 漏斗优化 | `/funnel-optimization $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 增长实验 | `/growth-experiment $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 病毒循环设计 | `/viral-loop-design $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速增长体检

编排器内轻量执行，不调用子技能。使用 `AskUserQuestion` 向用户逐项收集以下维度数据（接受估算值，标注"待验证"）：

| 维度 | 检查内容 | 判定标准 |
|------|---------|---------|
| 北极星指标 | 指标名称 + 当前值 + 近 30 天趋势 | 上升=绿 / 持平=黄 / 下降=红 |
| AARRR 均衡 | 获客、激活、留存、变现、推荐各取一个核心指标 | 与行业基准差距 >30% 的环节标红 |
| 实验速度 | 过去 30 天已完成实验数 + 成功率 | ≥8 次=绿 / 4-7 次=黄 / <4 次=红 |
| 单位经济 | LTV:CAC 比值 + CAC 回收期 | LTV>3×CAC=绿 / 2-3×=黄 / <2×=红 |

生成精简报告到 `_growth-hacking/quick-scan-{日期}.md`，包含：各维度红黄绿评分、Top 3 增长瓶颈（按影响力排序）、建议下一步行动。

⏸️ 使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_growth-hacking/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
增长实验必须包含假设 + 指标 + 最小样本量。
漏斗分析必须基于数据而非假设——无数据环节须标注"待验证"。
病毒系数 K 值计算必须标注数据来源和置信度。
所有增长策略必须通过单位经济验证：LTV > 3× CAC，否则标注"需验证经济模型"。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
