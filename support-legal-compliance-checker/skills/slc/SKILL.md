---
name: slc
description: 法律合规检查工作台——先装配合规任务，再按意图路由到合规审计、隐私政策、合同审查、快速扫描或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 法律合规检查工作台

用户传入的参数：`$ARGUMENTS`

先装配合规任务，再按意图路由到对应 workflow。不是所有需求都需要走完整审计 → 隐私政策 → 合同审查管道。

**入口纪律**：除非用户明确点名 `/compliance-audit`、`/privacy-policy`、`/contract-review`，或明确要求“只做审计 / 只做隐私政策 / 只做合同审查 / 只做快速扫描”，否则统一先走 `/support-legal-compliance-checker:slc` 入口。

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
| "合规 / 审计 / 法规 / 差距" | audit-only | 调用 `/compliance-audit $ARGUMENTS` |
| "隐私 / GDPR / PIPL / 政策" | privacy-only | 调用 `/privacy-policy $ARGUMENTS` |
| "合同 / 条款 / DPA / MSA / 审查" | contract-only | 调用 `/contract-review $ARGUMENTS` |
| "快速扫描 / 风险概览 / 快检" | quick-scan | → Step 3 |
| "继续上次合规任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整合规 / 全套" 或复杂需求 | full-compliance | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：audit-only / privacy-only / contract-only / quick-scan / full-compliance
- `workflow`：当前 workflow
- `task_slug`：任务简称
- `task_dir`：任务目录简称
- `resume_mode`：自动恢复 / 指定阶段 / 重新开始
- `jurisdiction_scope`：法域范围
- `deliverable_type`：审计报告 / 隐私政策 / 合同审查 / 合规包
- `regulation_scope`：适用法规列表
- `risk_focus`：高风险关注点
- `source_materials`：已提供材料
- `counsel_review_needed`：是否需要法律顾问复核
- `disclaimer_status`：免责声明状态
- `citation_mode`：法规引用粒度
- `artifact_paths`：最近产物
- `open_questions`：待确认问题
- `next_step`：下一步动作
- `current_stage`：当前阶段

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_legal-compliance/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` `audits/` `policies/` `contracts/`
4. 初始化 `meta/state.md`：

```markdown
workflow_mode: full-compliance
task_type: full-compliance
task_slug: {缩写}
task_dir: {缩写}
resume_mode: auto
jurisdiction_scope: []
deliverable_type: compliance-pack
regulation_scope: []
risk_focus: []
source_materials: []
counsel_review_needed: true
disclaimer_status: required
citation_mode: article-level
artifact_paths: []
open_questions: []
current_stage: compliance-audit
completed_steps: []
next_step: compliance-audit
updated_at: {YYYY-MM-DD}
```

5. 扫描已有目录，检查 `audits/`、`policies/`、`contracts/` 产物，产物优先于状态文件
6. 重新 Read `meta/state.md`，如 state 与产物冲突，以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 合规审计 | `/compliance-audit $ARGUMENTS` | `audits/*` 存在 | 继续 / 回退 / 结束 |
| 隐私政策 | `/privacy-policy $ARGUMENTS` | `policies/*` 存在 | 继续 / 回退 / 结束 |
| 合同审查 | `/contract-review $ARGUMENTS` | `contracts/*` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行），并标注法规引用、未决假设与需律师确认项。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速扫描

编排器内轻量执行，不调用子技能：
1. 优先读取最近任务的 `meta/state.md` 与 `audits/`、`policies/`、`contracts/` 产物
2. 输出适用法域、核心风险、法规引用完备度、待律师确认项四维速览
3. 每条结论必须带免责声明；没有明确法规依据时只能标注为待确认
4. 将结果写入 `_legal-compliance/quick-scan-{日期}.md`

使用 `AskUserQuestion`：深入审计 / 深入隐私政策 / 深入合同 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_legal-compliance/` 下未完成目录
2. 先 Read `meta/state.md`，再核对 `audits/`、`policies/`、`contracts/` 产物
3. 恢复时以产物优先于状态文件；若已有分析但引用不完整，下一步优先补法规引用与免责声明
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配合规任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
所有输出都必须明确标注“仅供参考，不构成正式法律意见”。
所有建议必须引用具体法规名称和条款编号；没有依据时只能标注为待确认。
不确定时必须标记为“需法律顾问确认”，不能把推测当法律结论。
不得越界替代律师或给出最终裁决。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
