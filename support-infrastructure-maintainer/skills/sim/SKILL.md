---
name: sim
description: 基础设施维护工作台——先装配基础设施任务，再按意图路由到监控体系、IaC 框架、备份恢复、快速诊断或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 基础设施维护工作台

用户传入的参数：`$ARGUMENTS`

先装配基础设施任务，再按意图路由到对应 workflow。不是所有需求都需要走完整监控 → IaC → 备份恢复管道。

**入口纪律**：除非用户明确点名 `/monitoring-setup`、`/iac-framework`、`/backup-recovery`，或明确要求“只做监控 / 只做 IaC / 只做备份 / 只做快速诊断”，否则统一先走 `/support-infrastructure-maintainer:sim` 入口。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ full-plan 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "监控 / 告警 / Prometheus / Grafana" | monitoring-only | 调用 `/monitoring-setup $ARGUMENTS` |
| "IaC / Terraform / 基础设施即代码" | iac-only | 调用 `/iac-framework $ARGUMENTS` |
| "备份 / 恢复 / 灾备 / DR" | backup-only | 调用 `/backup-recovery $ARGUMENTS` |
| "快速诊断 / 基础设施体检" | quick-diagnosis | → Step 3 |
| "继续上次基础设施任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整方案 / 全套" 或复杂需求 | full-plan | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：monitoring-only / iac-only / backup-only / quick-diagnosis / full-plan
- `workflow`：当前 workflow
- `route_reason`：为何进入当前 workflow
- `task_slug`：任务简称
- `cloud_env_arch_services`：云环境 / 架构 / 关键服务
- `slo_rto_rpo`：SLO / RTO / RPO 目标
- `budget_risk_compliance`：预算 / 风险 / 合规约束
- `selected_tracks`：监控 / IaC / 备份 / 安全
- `available_artifacts`：当前可用产物
- `deliverables`：希望产出的方案
- `completed_steps`：已完成阶段
- `artifact_paths`：产物路径
- `decision_log`：关键决策摘要
- `next_step`：下一步动作
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_infrastructure/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `monitoring/` `iac/` `backup/`
4. 初始化 `meta/workbench-state.md`：

```markdown
workflow_mode: full-plan
task_type: full-plan
route_reason: user-request
task_slug: {缩写}
cloud_env_arch_services: []
slo_rto_rpo: []
budget_risk_compliance: []
selected_tracks: [monitoring, iac, backup]
available_artifacts: []
deliverables: [infra-plan]
completed_steps: []
artifact_paths: []
decision_log: []
current_stage: monitoring-setup
next_step: monitoring-setup
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `monitoring/`、`iac/`、`backup/` 产物，产物优先于状态文件
6. 重新 Read `meta/workbench-state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/workbench-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 监控体系 | `/monitoring-setup $ARGUMENTS` | `monitoring/*` 存在 | 继续 / 回退 / 结束 |
| IaC 框架 | `/iac-framework $ARGUMENTS` | `iac/*` 存在 | 继续 / 回退 / 结束 |
| 备份恢复 | `/backup-recovery $ARGUMENTS` | `backup/*` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行），并补充 `decision_log`。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能：
1. 优先读取最近任务的 `meta/workbench-state.md` 与 `monitoring/`、`iac/`、`backup/` 产物
2. 输出监控覆盖、IaC 状态、备份健康、安全基线四维速览
3. 缺 SLO / RTO / RPO、未加密备份、过宽安全组等问题必须明确标红
4. 将结果写入 `_infrastructure/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入监控 / 深入 IaC / 深入备份 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_infrastructure/` 下未完成目录
2. 先 Read `meta/workbench-state.md`，再核对 `monitoring/`、`iac/`、`backup/` 产物
3. 恢复时以产物优先于状态文件；先从文件恢复，不依赖对话记忆
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配基础设施任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
监控必须覆盖 USE/RED 方法论关键指标。
备份方案必须有 RTO/RPO 目标和恢复演练计划。
IaC 方案必须考虑状态管理和 drift 检测。
安全基线问题必须显式标注风险等级。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
