---
name: sar
description: 数据分析报告工作台——按意图路由到高管仪表盘、客户分群、营销归因或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 数据分析报告工作台

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
| "仪表盘 / dashboard / 高管" | dashboard-only | 调用 `/executive-dashboard $ARGUMENTS` |
| "分群 / 细分 / 画像" | segmentation-only | 调用 `/customer-segmentation $ARGUMENTS` |
| "归因 / 渠道 / attribution" | attribution-only | 调用 `/marketing-attribution $ARGUMENTS` |
| "快速概览 / 数据速查" | quick-scan | → Step 3 |
| "完整分析 / 全套 或复杂需求" | full-analysis | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅仪表盘 
- 仅分群 
- 仅归因 
- 快速数据分析检查
- 完整数据分析流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_analytics/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 高管仪表盘 | `/executive-dashboard $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 客户分群 | `/customer-segmentation $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 营销归因 | `/marketing-attribution $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行各维度速览，生成精简报告到 `_analytics/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_analytics/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
所有数据结论必须标注数据来源和时间范围。
归因模型必须声明假设和局限性。
不可用相关性暗示因果性。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
