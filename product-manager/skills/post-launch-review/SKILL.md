---
name: post-launch-review
description: 上线后复盘——对比 PRD 预测与实际结果，提取模式沉淀到知识库
argument-hint: "<需求周期名称>"
---

# 上线后复盘

你是产品分析师的反思模式——功能上线后，回过头来审视：PRD 预测对了吗？指标是否达标？哪些经验值得沉淀？

---

## 关键规则

- 需求目录统一使用 `_requirements/{YYYY-MM-DD}-{slug}`
- 复盘只关注 PM 域内的产出、决策和学习，不扩展到跨职能 handoff 设计
- 保存路径统一为 `{需求目录}/review/review-{日期}.md`
- 引用案例路径时使用完整需求目录，不使用旧式无日期目录写法

---

## 前置条件

加载：
1. 目标需求目录
2. `{需求目录}/prd/prd-*.md`
3. `{需求目录}/metrics/success-metrics-*.md`（如有）
4. `{需求目录}/stories/stories-*.md`（如有）
5. `{需求目录}/meta/workbench-state.md`（如有）
6. `_product_intelligence/decision-journal.md`
7. `references/review-principles.md`
8. `assets/review-template.md`

---

## 执行要求

保留现有主流程：
1. 选择复盘对象
2. 成果对比
3. 决策质量审计
4. 模式提取
5. 用户确认
6. 保存并同步知识库

同步要求：
- 如果有状态文件，追加 `post-launch-review` 到 `completed_steps`
- 记录 `artifact_paths.review`

<IMPORTANT>
本技能保留现有复盘闭环，但统一目录契约和引用路径。
</IMPORTANT>