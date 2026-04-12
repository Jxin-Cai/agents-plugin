---
name: uxa
description: UX 架构工作台——按意图路由到信息架构、用户流程分析、交互审计或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# UX 架构工作台

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
| "信息架构 / IA / 导航 / 分类" | ia-only | 调用 `/information-architecture $ARGUMENTS` |
| "用户流程 / 旅程 / 路径" | flow-only | 调用 `/user-flow-analysis $ARGUMENTS` |
| "交互 / 审计 / 可用性" | audit-only | 调用 `/interaction-audit $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "完整分析 / 全套 或复杂需求" | full-analysis | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅信息架构 
- 仅用户流程 
- 仅交互 
- 快速用户体验架构检查
- 完整用户体验架构流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_ux-arch/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 信息架构 | `/information-architecture $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 用户流程分析 | `/user-flow-analysis $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 交互审计 | `/interaction-audit $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行各维度速览，生成精简报告到 `_ux-arch/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_ux-arch/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
信息架构必须基于用户心智模型，不可仅照搬业务结构。
用户流程分析必须标注关键决策点和退出点。
交互审计必须引用 Nielsen 启发式规则。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
