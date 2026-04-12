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
3. 使用 Bash(mkdir*) 创建 `_test-analysis/{当前日期}-{缩写}/` 及子目录 `context/`、`meta/`、`coverage/`、`failures/`、`reports/`
4. 使用 Write 初始化 `meta/state.md`（字段：workflow_mode=full-analysis、completed_steps=[]、next_step=coverage-analysis）
5. 使用 Glob 搜索 `_test-analysis/{当前日期}-{缩写}/coverage/*.md`、`failures/*.md`、`reports/*.md`，若某阶段产出文件已存在则标记该阶段为已完成；再 Read `meta/state.md` 交叉验证，产出文件与 state.md 冲突时以产出文件为准

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

1. 使用 Glob 搜索 `_test-analysis/*/meta/state.md`，对每个匹配目录 Read 其 `state.md`，筛选 `next_step` 不为 `done` 的目录即为未完成任务
2. 对每个未完成目录，使用 Glob 检查 `coverage/*.md`、`failures/*.md`、`reports/*.md` 是否存在，以产出文件实际存在情况确定已完成阶段（产出文件与 state.md 冲突时以产出文件为准）
3. 向用户展示未完成任务列表及各任务进度，使用 `AskUserQuestion`：从断点继续 / 重新开始 / 忽略

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
覆盖率分析必须区分行覆盖和分支覆盖。
失败分析必须有根因分类（代码/环境/数据/flaky）。
不可仅看覆盖率数字，需分析覆盖质量。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
