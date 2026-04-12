---
name: et
description: 实验跟踪工作台——按意图路由到A/B 测试设计、指标定义、结果分析或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 实验跟踪工作台

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
| "A/B 测试 / 实验设计 / 假设" | design-only | 调用 `/ab-test-design $ARGUMENTS` |
| "指标 / KPI / 北极星" | metrics-only | 调用 `/metrics-definition $ARGUMENTS` |
| "结果 / 分析 / 显著性" | analysis-only | 调用 `/results-analysis $ARGUMENTS` |
| "快速检查 / 实验状态" | quick-check | → Step 3 |
| "完整流程 / 全套 或复杂需求" | full-workflow | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅A
- 仅指标 
- 仅结果 
- 快速实验管理检查
- 完整实验管理流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_experiments/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| A/B 测试设计 | `/ab-test-design $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 指标定义 | `/metrics-definition $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 结果分析 | `/results-analysis $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行各维度速览，生成精简报告到 `_experiments/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_experiments/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
A/B 测试必须包含样本量计算和统计显著性标准。
结果分析必须区分统计显著与业务显著。
不可在实验未达到最小样本量时下结论。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
