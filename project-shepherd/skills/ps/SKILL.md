---
name: ps
description: 项目守护者工作台——按意图路由到健康检查、障碍清除、速率跟踪或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 项目守护者工作台

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
| "健康 / 状态 / 检查" | health-only | 调用 `/health-check $ARGUMENTS` |
| "障碍 / 阻塞 / blocker" | blocker-only | 调用 `/blocker-removal $ARGUMENTS` |
| "速率 / velocity / 燃尽" | velocity-only | 调用 `/velocity-tracking $ARGUMENTS` |
| "快速体检 / 概览" | quick-check | → Step 3 |
| "完整评审 / 全套 或复杂需求" | full-review | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅健康 
- 仅障碍 
- 仅速率 
- 快速项目健康管理检查
- 完整项目健康管理流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_project-health/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 健康检查 | `/health-check $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 障碍清除 | `/blocker-removal $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 速率跟踪 | `/velocity-tracking $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

使用 `AskUserQuestion` 一次性收集以下四维度速览信息：

| 维度 | 速览问题 |
|------|---------|
| 交付 | 最近迭代承诺达成率大约多少？发布是否按计划？ |
| 质量 | 最近发布后有几个生产缺陷？技术债务是否可控？ |
| 流程 | 团队同时进行中的工作项有多少？最大的流程瓶颈是什么？ |
| 团队 | 团队整体士气如何（1-5 分）？加班是否常态化？ |

将回答汇总为 `_project-health/quick-scan-{日期}.md`（不超过 30 行），每个维度标注红/黄/绿状态。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_project-health/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
健康检查必须产出可行动的待办项，不可仅列现象。
障碍必须有升级时间线和负责人建议。
速率趋势必须标注干扰因素。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
