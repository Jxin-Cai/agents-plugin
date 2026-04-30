---
name: ps
description: 项目守护者工作台——先装配项目守护任务，再按意图路由到健康检查、障碍清除、速率跟踪、快速体检或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 项目守护者工作台

用户传入的参数：`$ARGUMENTS`

先装配项目守护任务，再按意图路由到对应 workflow。不是所有需求都需要走完整健康 → 障碍 → 速率管道。

**入口纪律**：除非用户明确点名 `/health-check`、`/blocker-removal`、`/velocity-tracking`，或明确要求“只做健康检查 / 只做障碍清除 / 只做速率跟踪 / 只做快速体检”，否则统一先走 `/project-shepherd:ps` 入口。

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
| "健康 / 状态 / 检查" | health-only | 调用 `/health-check $ARGUMENTS` |
| "障碍 / 阻塞 / blocker" | blocker-only | 调用 `/blocker-removal $ARGUMENTS` |
| "速率 / velocity / 燃尽" | velocity-only | 调用 `/velocity-tracking $ARGUMENTS` |
| "快速体检 / 概览 / 快扫" | quick-check | → Step 3 |
| "继续上次项目守护任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整评审 / 全套" 或复杂需求 | full-review | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：health-only / blocker-only / velocity-only / quick-check / full-review
- `workflow`：当前 workflow
- `goal`：本次守护目标
- `deliverable`：健康报告 / 障碍清单 / 速率分析 / 完整守护包
- `risk`：当前最高风险
- `data_source`：口述 / 看板 / 度量 / 事故记录 / 本地文件
- `reuse_assets`：是否复用历史任务产物
- `resume_from`：自动恢复 / 指定阶段 / 重新开始
- `current_stage`：当前阶段
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_project-health/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `health/` `blockers/` `velocity/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-review
task_type: full-review
goal: {一句话目标}
deliverable: project-health-pack
risk: unknown
data_source: user-input
reuse_assets: auto
resume_from: auto
current_stage: health-check
completed_steps: []
next_step: health-check
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `health/`、`blockers/`、`velocity/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 健康检查 | `/health-check $ARGUMENTS` | `health/*.md` 存在 | 继续 / 回退 / 结束 |
| 障碍清除 | `/blocker-removal $ARGUMENTS` | `blockers/*.md` 存在 | 继续 / 回退 / 结束 |
| 速率跟踪 | `/velocity-tracking $ARGUMENTS` | `velocity/*.md` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速体检

编排器内轻量执行，不调用子技能：
1. 读取最近任务的健康、障碍、速率产物与状态摘要
2. 输出交付、质量、流程、团队四维速览，并标注红/黄/绿
3. 若数据不足，只标注缺口与建议采集项，不臆造健康判断
4. 将结果写入 `_project-health/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入健康检查 / 深入障碍清除 / 深入速率跟踪 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_project-health/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `health/`、`blockers/`、`velocity/` 产物
3. 恢复时以产物优先于状态文件；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配项目守护任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
健康检查必须产出可行动待办项，不可只列现象。
障碍清除必须标注影响范围、升级时间线和负责人建议。
速率趋势必须标注干扰因素与观察窗口，不可只给单点值。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
