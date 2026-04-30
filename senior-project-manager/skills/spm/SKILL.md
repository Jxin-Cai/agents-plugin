---
name: spm
description: 高级项目经理工作台——先装配项目管理任务，再按意图路由到风险评估、干系人地图、时间线规划、快速诊断或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 高级项目经理工作台

用户传入的参数：`$ARGUMENTS`

先装配项目管理任务，再按意图路由到对应 workflow。不是所有需求都需要走完整风险 → 干系人 → 时间线管道。

**入口纪律**：除非用户明确点名 `/risk-assessment`、`/stakeholder-map`、`/timeline-planning`，或明确要求“只做风险 / 只做干系人 / 只做时间线 / 只做快速诊断”，否则统一先走 `/senior-project-manager:spm` 入口。

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
| "风险 / 评估 / 应对" | risk-only | 调用 `/risk-assessment $ARGUMENTS` |
| "干系人 / 利益相关 / stakeholder" | stakeholder-only | 调用 `/stakeholder-map $ARGUMENTS` |
| "时间线 / 排期 / 里程碑" | timeline-only | 调用 `/timeline-planning $ARGUMENTS` |
| "快速诊断 / 概览 / 快扫" | quick-diagnosis | → Step 3 |
| "继续上次项目管理任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整规划 / 全套" 或复杂需求 | full-planning | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：risk-only / stakeholder-only / timeline-only / quick-diagnosis / full-planning
- `deliverable`：风险包 / 干系人地图 / 时间线 / 完整管理包
- `project_slug`：项目简称
- `risk_focus`：核心风险焦点
- `time_pressure`：时间压力级别
- `resume_intent`：自动恢复 / 指定阶段 / 重新开始
- `current_stage`：当前阶段
- `next_step`：下一步动作
- `updated_at`：最近更新时间

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_project-mgmt/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `risks/` `stakeholders/` `timeline/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-planning
task_type: full-planning
project_slug: {缩写}
deliverable: project-management-pack
risk_focus: unknown
time_pressure: medium
resume_intent: auto
current_stage: risk-assessment
completed_steps: []
next_step: risk-assessment
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `risks/`、`stakeholders/`、`timeline/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 风险评估 | `/risk-assessment $ARGUMENTS` | `risks/risk-register-*.md` 存在 | 继续 / 回退 / 结束 |
| 干系人地图 | `/stakeholder-map $ARGUMENTS` | `stakeholders/stakeholder-map-*.md` 存在 | 继续 / 回退 / 结束 |
| 时间线规划 | `/timeline-planning $ARGUMENTS` | `timeline/timeline-plan-*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速诊断

编排器内轻量执行，不调用子技能：
1. 从用户描述或最近任务中提取 Top 风险、关键干系人、关键路径压力点
2. 若数据不足，只输出初步诊断和待补信息，不直接生成完整计划
3. 将速览写入 `_project-mgmt/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入风险 / 深入干系人 / 深入时间线 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_project-mgmt/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `risks/`、`stakeholders/`、`timeline/` 产物
3. 恢复时以产物优先于状态文件；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配项目管理任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
风险评估必须量化概率 × 影响，不可只给模糊判断。
时间线必须标注关键路径、缓冲区和时间压力来源。
干系人地图必须区分影响力和利益维度。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
