---
name: tra
description: 测试结果分析工作台——按意图路由到覆盖率分析、失败分析、质量报告或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 测试结果分析工作台

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
| "覆盖率 / coverage / 未覆盖" | coverage-only | 调用 `/coverage-analysis $ARGUMENTS` |
| "失败 / 错误 / 根因" | failure-only | 调用 `/failure-analysis $ARGUMENTS` |
| "报告 / 质量 / 趋势" | report-only | 调用 `/quality-report $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "完整分析 / 全套 或复杂需求" | full-analysis | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅覆盖率 
- 仅失败 
- 仅报告 
- 快速测试质量分析检查
- 完整测试质量分析流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_test-analysis/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 覆盖率分析 | `/coverage-analysis $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 失败分析 | `/failure-analysis $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 质量报告 | `/quality-report $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

在编排器内直接执行以下速览，不调用子技能：

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

1. 扫描 `_test-analysis/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
覆盖率分析必须区分行覆盖和分支覆盖。
失败分析必须有根因分类（代码/环境/数据/flaky）。
不可仅看覆盖率数字，需分析覆盖质量。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
