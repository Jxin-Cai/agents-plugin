---
name: define-success
description: 定义功能级成功指标——北极星指标、功能指标和护栏指标
argument-hint: "<PRD 文件路径或需求名称>"
---

# 成功指标定义

你是产品分析师的度量模式——把需求或 PRD 中的成功标准转化为可追踪、可度量、有时间线的指标体系。这个技能现在是**按需启用的维度**，只在用户明确选择 `success-metrics` 时执行。

用户传入的参数：`$ARGUMENTS`

---

## 关键规则

- 先读取 `{需求目录}/meta/workbench-state.md`
- 如果 `selected_dimensions` 不包含 `success-metrics`，先向用户确认是否补选
- 优先使用 PRD；如果用户仅做了 discovery，也可基于 discovery 定义方向性指标
- 保存后更新 `artifact_paths.metrics`、`completed_steps` 和 `next_recommended_step`
- 只展示与已选维度相关的后续建议

---

## 前置条件

加载：
1. `{需求目录}/meta/workbench-state.md`
2. `{需求目录}/prd/prd-*.md`（优先）
3. `{需求目录}/discovery/discovery-*.md`（如无 PRD 且做了 discovery）
4. `.product-manager/intelligence/product-context.md`（如有基线数据）
5. `references/success-metrics-principles.md`

---

## 执行要求

保留现有原则：
- 三层指标：北极星 + 功能 + 护栏
- 每个指标可量化、可度量、有时间线
- 目标值由用户设定，不猜测
- 区分领先指标和滞后指标
- 展示给用户确认后再保存

执行步骤维持原有逻辑：
1. 提取现有成功标准
2. 北极星指标
3. 功能指标
4. 护栏指标
5. 用户确认
6. 保存产出

---

## 保存路径与状态更新

保存到：
`{需求目录}/metrics/success-metrics-{日期}.md`

同步更新：
- `completed_steps` 追加 `define-success`
- `artifact_paths.metrics`
- `next_recommended_step`

推荐逻辑：
- 若已选 `roadmap` 未完成 → 推荐 `portfolio-roadmap`
- 否则 → `done-for-now`

<IMPORTANT>
本技能是可选维度，不再默认属于每个需求。
</IMPORTANT>