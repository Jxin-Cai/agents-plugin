---
name: pdo
description: 私域运营工作台——先装配私域任务，再按意图路由到企微生态搭建、社群运营、用户生命周期、全链路转化、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 私域运营工作台

用户传入的参数：`$ARGUMENTS`

先装配私域运营任务，再按意图路由到对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：除非用户明确点名 `/wecom-ecosystem-setup`、`/community-operations`、`/user-lifecycle`、`/conversion-funnel`，或明确要求“只做企微 / 只做社群 / 只做生命周期 / 只做转化 / 只做快速检查”，否则统一先走 `/private-domain-operator:pdo` 入口。

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
| "企微 / 企业微信 / 搭建" | wecom-only | 调用 `/wecom-ecosystem-setup $ARGUMENTS` |
| "社群 / 社区 / 运营" | community-only | 调用 `/community-operations $ARGUMENTS` |
| "生命周期 / 留存 / 召回" | lifecycle-only | 调用 `/user-lifecycle $ARGUMENTS` |
| "转化 / 漏斗 / 成交" | conversion-only | 调用 `/conversion-funnel $ARGUMENTS` |
| "检查 / 盘点 / 概览 / 快速看看" | quick-scan | → Step 3 |
| "继续上次私域任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整策略 / 全套" 或复杂需求 | full-strategy | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：wecom-only / community-only / lifecycle-only / conversion-only / quick-scan / full-strategy
- `objective`：本次运营目标
- `trigger_source`：用户口述 / 历史盘点 / 外部活动 / 数据异常
- `deliverable_type`：蓝图 / SOP / 生命周期策略 / 转化方案 / 全流程包
- `scope_in`：本次纳入范围
- `scope_out`：本次排除范围
- `business_stage`：冷启动 / 成长期 / 稳定期 / 大促期
- `channel_mix`：公域引流来源
- `audience_segment`：目标人群分层
- `current_assets`：已有私域资产
- `risk_profile`：当前最高风险
- `compliance_constraints`：合规约束
- `budget_window`：预算窗口
- `kpi_targets`：核心 KPI
- `workflow_candidate`：当前 workflow
- `fast_route`：是否快路由
- `task_slug`：任务简称
- `current_stage`：当前阶段
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_private-domain/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `ecosystem/` `community/` `lifecycle/` `funnel/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-strategy
task_type: full-strategy
task_slug: {缩写}
objective: {一句话目标}
trigger_source: user-input
deliverable_type: private-domain-pack
scope_in:
scope_out:
business_stage: unknown
channel_mix: []
audience_segment: []
current_assets: []
risk_profile: unknown
compliance_constraints: []
budget_window: unknown
kpi_targets: []
workflow_candidate: full-strategy
fast_route: false
current_stage: wecom-ecosystem-setup
completed_steps: []
next_step: wecom-ecosystem-setup
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `ecosystem/`、`community/`、`lifecycle/`、`funnel/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 企微生态搭建 | `/wecom-ecosystem-setup $ARGUMENTS` | `ecosystem/*` 存在 | 继续 / 回退 / 结束 |
| 社群运营 | `/community-operations $ARGUMENTS` | `community/*` 存在 | 继续 / 回退 / 结束 |
| 用户生命周期 | `/user-lifecycle $ARGUMENTS` | `lifecycle/*` 存在 | 继续 / 回退 / 结束 |
| 全链路转化 | `/conversion-funnel $ARGUMENTS` | `funnel/*` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行，不调用子技能：
1. 优先扫描最近任务的 `meta/state.md` 与四类阶段产物
2. 输出企微基建、社群健康、生命周期、转化漏斗四维速览
3. 若缺真实数据，仅生成缺口说明和建议采集项，不臆造 KPI
4. 将速览结果保存到 `_private-domain/quick-scan-{当前日期}.md`

使用 `AskUserQuestion`：深入企微 / 深入社群 / 深入生命周期 / 深入转化 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_private-domain/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `ecosystem/`、`community/`、`lifecycle/`、`funnel/` 产物
3. 恢复时以产物优先于状态文件；切 workflow 时记录决策日志
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配私域任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
转化漏斗必须有可量化 KPI，不可只给方向。
用户生命周期必须包含触发式自动化规则。
社群运营方案必须考虑人力可执行性与触达频率。
合规风险必须前置标注，不可默认忽略。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
