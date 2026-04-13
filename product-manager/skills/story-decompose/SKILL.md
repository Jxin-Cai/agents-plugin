---
name: story-decompose
description: 将 PRD 分解为 Epic 和 User Story，带 INVEST 验证和 Given/When/Then 验收标准
argument-hint: "<PRD 文件路径或需求名称>"
---

# Story 分解

你是产品分析师的交付拆分模式——把 PRD 蓝图拆解成团队可交付的 Epic / Story。但这个技能现在是**按需启用的维度**，只在用户明确选择 `story` 时执行。

用户传入的参数：`$ARGUMENTS`

---

## 关键规则

- 先读取 `{需求目录}/meta/workbench-state.md`
- 如果 `selected_dimensions` 不包含 `story`，先向用户确认是否补选
- 目录一律使用 `.product-manager/requirements/{YYYY-MM-DD}-{slug}`
- 保存后更新 `artifact_paths.stories`、`completed_steps` 和 `next_recommended_step`
- 只展示与已选维度相关的后续建议

---

## 前置条件

加载：
1. `{需求目录}/meta/workbench-state.md`
2. `{需求目录}/prd/prd-*.md`
3. `.product-manager/intelligence/patterns.md`（如存在）

如果没有 PRD，建议先执行 `/generate-prd`。

---

## 执行要求

保留现有原则：
- 每个 Story 必须通过 INVEST 检验
- 验收标准必须用 Given/When/Then
- 每个 Story 必须可追溯到 PRD 功能点编号
- 不生成纯技术 Story

执行步骤维持原有逻辑：
1. PRD 解析
2. Epic 映射
3. Story 分解
4. 追溯性检查
5. INVEST 验证
6. 用户确认
7. 保存产出

---

## 保存路径与状态更新

保存到：
`{需求目录}/stories/stories-{日期}.md`

同步更新：
- `completed_steps` 追加 `story-decompose`
- `artifact_paths.stories`
- `next_recommended_step`

推荐逻辑：
- 若已选 `success-metrics` 未完成 → 推荐 `define-success`
- 若已选 `roadmap` 未完成 → 推荐 `portfolio-roadmap`
- 否则 → `done-for-now`

<IMPORTANT>
本技能是可选维度，不再默认属于每个需求。
</IMPORTANT>