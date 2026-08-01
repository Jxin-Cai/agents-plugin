# PM 产物契约

## 目录契约

需求型：`.product-manager/requirements/{YYYY-MM-DD}-{slug}/`  
子目录：`raw/ domain/ discovery/ prd/ stories/ metrics/ nfr/ governance/ review/ meta/`

组合/路线图：`.product-manager/portfolio/{YYYY-MM-DD}-{slug}/`  
子目录：`opportunities/ priority/ roadmap/ meta/`

独立 discovery：`.product-manager/discovery/{YYYY-MM-DD}-{slug}/`

知识库：`.product-manager/intelligence/`

## 状态文件

唯一状态文件：`meta/workbench-state.md`

基础字段：`workflow_mode`、`slug`、`requirement_dir`、`selected_dimensions`、`completed_steps`、`next_recommended_step`、`artifact_paths`。

SDD 闭环字段：

```yaml
spec_state: draft | approved | in-development | shipped | retired
quality_gate:
  status: pending | passed | failed
  report_path: ""
  failed_items: []
slice_status: pending | ready | partial
uat_status: pending | ready | waived
state_history:
  - from: draft
    to: approved
    at: {YYYY-MM-DD}
    reason: Spec Quality Gate passed
knowledge_sync:
  decision_journal: initialized | synced | pending
  domain_glossary: initialized | synced | pending
  patterns: initialized | synced | pending
  product_context: initialized | synced | pending
  archive: synced | pending
```

缺失新字段的旧状态文件必须按默认值补齐：`spec_state: draft`、`quality_gate.status: pending`、`slice_status: pending`、`uat_status: pending`。

运行时状态只放这里；PRD frontmatter 的 `status` 仅镜像 `spec_state`，不承载执行过程细节。

## 规格状态机

| 状态 | 进入条件 | 守卫 |
|------|----------|------|
| `draft` | 完成需求澄清或 PRD 仍需修订 | 不允许发布到需求平台 |
| `approved` | PRD 通过 Spec Quality Gate | 可进入 Story 切片和 UAT |
| `in-development` | Story 进入开发阶段 | — |
| `shipped` | 完成上线复盘 | 知识回流候选应标记 pending |
| `retired` | 完成归档与知识回流 | 需求周期只读归档 |

发布守卫：`quality_gate.status` 必须为 `passed`，`slice_status` 应为 `ready`，`uat_status` 必须为 `ready` 或 `waived`。如不满足，必须停下来让用户选择补齐、豁免或取消。

## PRD frontmatter（v2）

```yaml
---
type: prd
version: 2
status: draft | approved | in-development | shipped | retired
created: {YYYY-MM-DD}
slug: {需求简写}
requirement_dir: .product-manager/requirements/{YYYY-MM-DD}-{slug}
workflow_mode: requirement-delivery
selected_dimensions: [prd, story, success-metrics]
domain: {领域}
domainComplexity: {低 | 中 | 高}
nfr_profile: [performance, reliability, auditability]
compliance_profile: [PCI-DSS, AML/KYC]
---
```

## 统一规则

1. 目录统一用 `.product-manager/requirements/{YYYY-MM-DD}-{slug}`，不用无日期写法
2. PM 工作台只做 PM 域内路由
3. 用户没有选择的分析维度，不自动生成对应产物