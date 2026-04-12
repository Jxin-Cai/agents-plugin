---
name: spm
description: 高级项目经理工作台——按意图路由到风险评估、干系人地图、时间线规划或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 高级项目经理工作台

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
| "风险 / 评估 / 应对" | risk-only | 调用 `/risk-assessment $ARGUMENTS` |
| "干系人 / 利益相关 / stakeholder" | stakeholder-only | 调用 `/stakeholder-map $ARGUMENTS` |
| "时间线 / 排期 / 里程碑" | timeline-only | 调用 `/timeline-planning $ARGUMENTS` |
| "快速诊断 / 概览" | quick-diagnosis | → Step 3 |
| "完整规划 / 全套 或复杂需求" | full-planning | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅风险 
- 仅干系人 
- 仅时间线 
- 快速项目管理检查
- 完整项目管理流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_project-mgmt/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 用 Glob 扫描 `_project-mgmt/` 下已有日期目录；若存在同名目录，Read `meta/state.md` 获取 `next_step`，再用 Glob 检查各阶段产出文件（`risks/*.md`、`stakeholders/*.md`、`timeline/*.md`）——产出文件存在则视为该阶段已完成，覆盖 state.md 中的记录

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

## Step 3: 快速检查

对 `$ARGUMENTS` 中描述的项目，在编排器内逐维度生成速览表，不调用子技能。

| 维度 | 检查项 | 输出内容 |
|------|--------|---------|
| 风险 | 从项目描述推断 Top 3 风险 | 风险名称 + 概率/影响初步判断（高/中/低） |
| 干系人 | 从项目描述推断关键角色 | 角色名称 + 权力/利益象限（密切管理/保持满意/保持知情/持续监控） |
| 进度 | 从项目描述推断阶段划分 | 阶段名称 + 预估周期 + 是否在关键路径 |

输出：Write 到 `_project-mgmt/quick-scan-{日期}.md`，每个维度不超过 10 行，总计不超过 40 行。

使用 `AskUserQuestion` 向用户展示选项：深入某个维度（调用对应子技能）/ 进入完整流程 / 结束。

---

## 断点恢复

1. 用 Glob 列出 `_project-mgmt/*/meta/state.md`，Read 每个文件筛选 `next_step` 不为 `done` 的目录
2. 对该目录 Read `meta/state.md`，获取 `workflow_mode`、`completed_steps`、`next_step`
3. 用 Glob 检查阶段产出文件（`risks/risk-register-*.md`、`stakeholders/stakeholder-map-*.md`、`timeline/timeline-plan-*.md`），若产出文件存在但 `completed_steps` 未记录，以产出文件为准修正进度
4. 使用 `AskUserQuestion` 向用户展示当前进度和选项：从断点继续 / 重新开始 / 选择其他任务

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
风险评估必须有影响×概率矩阵。
时间线必须标注关键路径和缓冲区。
干系人地图必须区分影响力和利益维度。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
