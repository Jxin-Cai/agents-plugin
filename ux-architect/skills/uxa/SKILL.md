---
name: uxa
description: UX 架构工作台——先装配任务，再按意图路由到信息架构、用户流程分析、交互审计、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# UX 架构工作台

用户传入的参数：`$ARGUMENTS`

先装配 UX 架构任务，再带他进入对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：凡自然语言 UX 请求（信息架构 / 流程 / 交互 / 体验审计 / 快速检查），默认先走 `/ux-architect:uxa` 装配任务；仅当用户明确点名子 skill（`/information-architecture`、`/user-flow-analysis`、`/interaction-audit`）或明确说“只做某一项”时，才直达子 skill。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "信息架构 / IA / 导航 / 分类" | ia-only | 调用 `/information-architecture $ARGUMENTS` |
| "用户流程 / 旅程 / 路径" | flow-only | 调用 `/user-flow-analysis $ARGUMENTS` |
| "交互 / 审计 / 可用性" | audit-only | 调用 `/interaction-audit $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "继续上次 UX 架构任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整分析 / 全套" 或复杂需求 | full-analysis | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：ia-only / flow-only / audit-only / quick-scan / full-analysis
- `objective`：一句话目标
- `trigger_source`：new-feature / redesign / incident / optimization
- `deliverable_type`：IA / flow / audit / 组合交付物
- `scope_in`：纳入分析的页面 / 流程 / 角色
- `scope_out`：排除项
- `risk_profile`：关键体验风险
- `persona_matrix`：核心用户 / 角色
- `constraints`：时间 / 资源 / 业务约束
- `workflow_candidate`：候选 workflow

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_ux-arch/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `ia/` `flows/` `interaction/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-analysis
task_type: full-analysis
objective: {一句话目标}
trigger_source: redesign
deliverable_type: audit-pack
scope_in: []
scope_out: []
risk_profile: []
persona_matrix: []
constraints: []
completed_steps: []
next_step: information-architecture
last_artifact: 
```

5. 使用 Glob 扫描 `ia/ia-*.md`、`flows/flow-*.md`、`interaction/audit-*.md`，如产物已存在则标记对应阶段已完成
6. Read `meta/state.md` 校验接续点；产物优先于状态文件

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

在编排器内依次执行以下速览（不调用子技能），生成精简报告到 `_ux-arch/quick-scan-{日期}.md`：

| 维度 | 速览动作 | 输出 |
|------|---------|------|
| 信息架构 | 使用 Glob 扫描 `src/**/route*`、`src/**/page*`、`src/**/nav*`、`src/**/layout*` 等文件，Read 提取一级导航入口并统计层级深度 | IA 速览（≤10 行） |
| 用户流程 | 基于导航入口识别 Top 3 核心任务，逐一列出 Happy Path 步骤数和关键决策点 | 流程速览（≤10 行） |
| 交互设计 | 对照 Nielsen H1-H4（可见性/匹配/控制/一致性），逐条检查首页或核心页面的交互反馈、术语使用、撤销能力、样式一致性 | 交互速览（≤10 行） |

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 使用 Glob 扫描 `_ux-arch/*/meta/state.md`，Read 每个 state.md 检查 `next_step` 字段
2. 若 `next_step` 不为 `done`，使用 Glob 检查对应阶段产出文件（`ia/ia-*.md`、`flows/flow-*.md`、`interaction/audit-*.md`）是否存在；产出文件存在则视为该阶段已完成
3. 产物优先于状态文件；恢复时补问只问缺口字段
4. 使用 `AskUserQuestion` 向用户展示进度，选择：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配 UX 架构任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
信息架构必须基于用户心智模型，不可仅照搬业务结构。
用户流程分析必须标注关键决策点和退出点。
交互审计必须引用 Nielsen 启发式规则。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
