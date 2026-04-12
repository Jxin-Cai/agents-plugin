---
name: sr
description: 客户支持工作台——按意图路由到工单处理、知识库、支持分析或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 客户支持工作台

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
| "工单 / 处理 / 响应" | ticket-only | 调用 `/ticket-resolution $ARGUMENTS` |
| "知识库 / FAQ / 文档" | kb-only | 调用 `/knowledge-base $ARGUMENTS` |
| "分析 / 报告 / 趋势" | analytics-only | 调用 `/support-analytics $ARGUMENTS` |
| "快速检查 / 概览" | quick-check | → Step 3 |
| "完整体系 / 全套 或复杂需求" | full-system | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅工单 
- 仅知识库 
- 仅分析 
- 快速客户支持体系检查
- 完整客户支持体系流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_support/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 工单处理 | `/ticket-resolution $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 知识库 | `/knowledge-base $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 支持分析 | `/support-analytics $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行各维度速览，生成精简报告到 `_support/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_support/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
工单处理流程必须有 SLA 标准。
知识库文章必须有版本和过期策略。
分析报告必须区分事实与推断。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
