---
name: pb
description: 性能基准测试工作台——按意图路由到负载测试计划、性能分析指南、优化报告或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(mkdir*|find*|ls*|wc*)", "AskUserQuestion", "Skill"]
---

# 性能基准测试工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整管道。

---

## 强制执行规则

- 始终用中文与用户沟通
- 先识别 workflow 类型，再进入对应流程
- 不默认跑完整管道
- 不在入口全量加载所有 references
- 每个阶段完成后等待用户确认

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
5. 用 Glob 扫描 `_performance/{目录}/` 下 `load-tests/`、`profiling/`、`reports/` 中的产物文件，判断接续点——产物存在则跳过对应阶段

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 负载测试计划 | `/load-test-plan $ARGUMENTS` | `load-tests/load-test-plan-*.md` 存在 | 继续 / 回退 / 结束 |
| 性能分析指南 | `/profiling-guide $ARGUMENTS` | `profiling/profiling-guide-*.md` 存在 | 继续 / 回退 / 结束 |
| 优化报告 | `/optimization-report $ARGUMENTS` | `reports/optimization-report-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

使用 Glob 扫描项目源码目录（`**/*.{java,py,go,ts,js,rs}`），按以下维度逐项检查并生成精简报告到 `_performance/quick-scan-{日期}.md`：

| 维度 | 具体检查动作 | 输出 |
|------|-------------|------|
| 响应延迟 | 用 Grep 搜索同步 I/O 调用（`readFileSync`/`requests.get`/`jdbc.execute` 等）、N+1 查询模式（循环内 DB 调用）、无缓存热点（重复计算/重复查询） | 风险点列表（文件:行号 + 影响评估） |
| 资源利用 | 用 Grep 搜索连接池/线程池配置（`pool.size`/`max-connections`/`thread-pool`），Read 配置文件检查内存分配参数 | 配置建议（当前值 → 建议值 + 理由） |
| 并发安全 | 用 Grep 搜索共享可变状态（`static mut`/全局变量写入/`synchronized`），检查锁策略和竞态条件 | 风险点列表（严重度 + 修复方向） |
| 可扩展性 | 用 Grep 搜索硬编码限制（`MAX_`/`LIMIT_`/魔数），检查有状态组件和单点瓶颈 | 改进方向（短期 + 长期） |

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 用 Glob 扫描 `_performance/` 下各任务目录，识别未完成任务
2. Read `meta/state.md`，获取 `completed_steps` 和 `next_step`
3. 用 Glob 检查各阶段产物文件是否存在——**产物优先于状态文件**（如 `load-tests/*.md` 存在则视为该阶段已完成，即使 state.md 未更新）
4. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
## 不可违反的规则
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。

## 性能工程硬规则
1. 延迟指标必须使用百分位（P50/P95/P99），禁止使用均值——均值掩盖长尾问题
2. 负载测试必须有可量化的验收标准（响应时间阈值 + 吞吐量下限 + 错误率上限），缺一不可
3. 不可在无基线数据时声称"性能提升 X%"——优化前后必须在相同条件下对比
4. 资源利用率数据必须标注采样窗口和统计口径（如"5 分钟平均 CPU 利用率 72%"），禁止无上下文裸数字
</IMPORTANT>
