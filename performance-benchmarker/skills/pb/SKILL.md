---
name: pb
description: 性能基准测试工作台——按意图路由到负载测试计划、性能分析指南、优化报告或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 性能基准测试工作台

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
| "负载 / 压测 / 并发 / QPS" | load-test-only | 调用 `/load-test-plan $ARGUMENTS` |
| "分析 / profiling / 火焰图" | profiling-only | 调用 `/profiling-guide $ARGUMENTS` |
| "优化 / 报告 / 对比" | optimization-only | 调用 `/optimization-report $ARGUMENTS` |
| "快速诊断 / 性能体检" | quick-diagnosis | → Step 3 |
| "完整基准 / 全套 或复杂需求" | full-benchmark | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅负载 
- 仅分析 
- 仅优化 
- 快速性能优化检查
- 完整性能优化流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_performance/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 负载测试计划 | `/load-test-plan $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 性能分析指南 | `/profiling-guide $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 优化报告 | `/optimization-report $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行各维度速览，生成精简报告到 `_performance/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_performance/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
负载测试必须有明确的验收标准（响应时间/吞吐量/错误率）。
优化必须有 before/after 量化对比。
不可在无基线数据时声称「性能提升 X%」。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
