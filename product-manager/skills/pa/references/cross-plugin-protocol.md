# PM 产物契约

## 目录契约

需求型：`_requirements/{YYYY-MM-DD}-{slug}/`  
子目录：`raw/ domain/ discovery/ prd/ stories/ metrics/ nfr/ governance/ review/ meta/`

组合/路线图：`_portfolio/{YYYY-MM-DD}-{slug}/`  
子目录：`opportunities/ priority/ roadmap/ meta/`

独立 discovery：`_discovery/{YYYY-MM-DD}-{slug}/`

知识库：`_product_intelligence/`

## 状态文件

唯一状态文件：`meta/workbench-state.md`

记录 `workflow_mode`、`selected_dimensions`、`completed_steps`、`next_recommended_step`、`artifact_paths`。涉及知识库同步时追加 `knowledge_sync`（synced / pending）。

运行时状态只放这里，不写进 PRD frontmatter。

## PRD frontmatter（v2）

```yaml
---
type: prd
version: 2
status: draft | approved | in-development | shipped | retired
created: {YYYY-MM-DD}
slug: {需求简写}
requirement_dir: _requirements/{YYYY-MM-DD}-{slug}
workflow_mode: requirement-delivery
selected_dimensions: [prd, story, success-metrics]
domain: {领域}
domainComplexity: {低 | 中 | 高}
nfr_profile: [performance, reliability, auditability]
compliance_profile: [PCI-DSS, AML/KYC]
---
```

## 统一规则

1. 目录统一用 `_requirements/{YYYY-MM-DD}-{slug}`，不用无日期写法
2. PM 工作台只做 PM 域内路由
3. 用户没有选择的分析维度，不自动生成对应产物