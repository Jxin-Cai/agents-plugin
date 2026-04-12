---
name: jws
description: Jira 工作流工作台——按意图路由到工作流设计、问题分类、看板优化或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# Jira 工作流工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整设计 → 分类 → 看板管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整三阶段管道
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "工作流 / 状态 / 转换 / 流程设计" | workflow-only | 调用 `/workflow-design $ARGUMENTS` |
| "分类 / 分诊 / triage / 优先级" | triage-only | 调用 `/issue-triage $ARGUMENTS` |
| "看板 / board / Kanban / WIP" | board-only | 调用 `/board-optimization $ARGUMENTS` |
| "快速检查 / 诊断" | quick-check | → Step 3 |
| "完整流程 / 全套" 或复杂需求 | full-workflow | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 完整 Jira 工作流优化（推荐）
- 仅工作流设计
- 仅问题分类体系
- 仅看板优化
- 快速工作流诊断

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_jira-workflow/{当前日期}-{缩写}/` 及子目录 `context/` `workflows/` `triage/` `boards/` `meta/`
4. **需求平台连接检查**：检查 `.requirement-mgmt/config.yaml`，若不存在，询问是否配置（调用 `/req-setup`）
5. 初始化 `meta/workflow-state.md`（workflow_mode、completed_steps、next_step）
6. 扫描已有目录，检查接续点（产物优先）

**⏸️ 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/workflow-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 工作流设计 | `/workflow-design $ARGUMENTS` | `workflows/workflow-*.md` | 继续 / 重新设计 / 结束 |
| 问题分类 | `/issue-triage $ARGUMENTS` | `triage/triage-*.md` | 继续 / 调整 / 回退 |
| 看板优化 | `/board-optimization $ARGUMENTS` | `boards/board-*.md` | 完成 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速工作流诊断

编排器内轻量执行：
1. 当前工作流状态数和转换规则概览
2. WIP 限制合理性检查
3. 常见瓶颈状态识别（堆积最多的状态）

生成精简报告到 `_jira-workflow/quick-check-{日期}.md`。

---

## 断点恢复

1. 扫描 `_jira-workflow/` 下未完成目录
2. Read `meta/workflow-state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
工作流设计必须验证转换规则的完整性（无死锁状态）。
看板优化必须包含 WIP 限制建议。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
