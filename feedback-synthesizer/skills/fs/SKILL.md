---
name: fs
description: 反馈综合分析工作台——按意图路由到反馈收集、情感分析、洞察提取或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 反馈综合分析工作台

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
| "收集 / 采集 / 汇总反馈" | collect-only | 调用 `/feedback-collection $ARGUMENTS` |
| "情感 / 情绪 / 正负面" | sentiment-only | 调用 `/sentiment-analysis $ARGUMENTS` |
| "洞察 / 提炼 / 趋势" | insight-only | 调用 `/insight-extraction $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "完整分析 / 全套 或复杂需求" | full-synthesis | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅收集 
- 仅情感 
- 仅洞察 
- 快速反馈分析检查
- 完整反馈分析流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_feedback/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 反馈收集 | `/feedback-collection $ARGUMENTS` | `raw-feedback/feedback-*.md` 存在 | 继续 / 回退 / 结束 |
| 情感分析 | `/sentiment-analysis $ARGUMENTS` | `analysis/sentiment-*.md` 存在 | 继续 / 回退 / 结束 |
| 洞察提取 | `/insight-extraction $ARGUMENTS` | `insights/insights-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段完成后：
1. Read 子技能产出文件，Write 不超过 20 行的摘要到 `meta/{stage}-summary.md`
2. 更新 `meta/state.md` 的 completed_steps 和 next_step
3. 使用 `AskUserQuestion` 展示选项：继续下一阶段 / 回退重做 / 结束

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

使用 Glob 扫描 `_feedback/` 下最近的工作目录（如无则请用户提供数据源），按以下维度执行速览：

| 维度 | 检查动作 | 输出 |
|------|---------|------|
| 渠道覆盖 | 统计反馈来源渠道数和各渠道占比 | 单渠道偏差预警 |
| 情感分布 | 抽样 10-15 条反馈快速标注正/负/中 | 整体情感倾向 |
| 高频主题 | 识别出现 ≥3 次的关键词或主题 | Top 3 高频主题 |
| 紧急信号 | 检查是否有功能故障、数据丢失等严重负面 | 红旗标记 |

将速览结果 Write 到 `_feedback/quick-scan-{日期}.md`（渠道覆盖 + 情感分布 + Top 主题 + 紧急信号 + 建议下一步）。

使用 `AskUserQuestion` 展示速览结果并提供选项：深入某个维度 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_feedback/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
洞察必须有原始反馈引用支撑，不可凭空推断。
情感分析必须附带典型引言。
数据量不足时必须声明置信度限制。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
