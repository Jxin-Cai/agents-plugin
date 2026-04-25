---
name: story-decompose
description: 将 PRD 分解为 Epic 和 User Story，带 INVEST 验证和 Given/When/Then 验收标准
argument-hint: "<PRD 文件路径或需求名称>"
---

# Story 分解

你是产品分析师的交付拆分模式——把 PRD 蓝图拆解成团队可交付的 Epic / Story。但这个技能现在是**按需启用的维度**，只在用户明确选择 `story` 时执行。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

使用 Read 工具加载以下引用文件，严格遵守其中规则：

- `references/story-decompose-principles.md` — Story 分解、INVEST、独立交付切片规则
- `assets/story-template.md` — Story 输出模板
- `assets/uat-pack-template.md` — UAT 验收包模板

---

## 关键规则

- 先读取 `{需求目录}/meta/workbench-state.md`
- 如果 `selected_dimensions` 不包含 `story`，先向用户确认是否补选
- 如果 `quality_gate.status` 不是 `passed`，先提示用户回到 `/generate-prd` 修订 PRD 或明确选择继续草稿切片
- 目录一律使用 `.product-manager/requirements/{YYYY-MM-DD}-{slug}`
- 保存后更新 `artifact_paths.stories`、`artifact_paths.uat_pack`（如生成）、`completed_steps` 和 `next_recommended_step`
- 保存后更新 `slice_status: ready | partial`、`uat_status: ready | waived | pending`
- 只展示与已选维度相关的后续建议

---

## 前置条件

加载：
1. `{需求目录}/meta/workbench-state.md`
2. `{需求目录}/prd/prd-*.md`
3. `{需求目录}/metrics/success-metrics-*.md`（如存在）
4. `{需求目录}/nfr/nfr-*.md`（如存在）
5. `{需求目录}/governance/governance-*.md`（如存在）
6. `.product-manager/intelligence/patterns.md`（如存在）

如果没有 PRD，建议先执行 `/generate-prd`。

---

## 执行要求

保留现有原则：
- 每个 Story 必须通过 INVEST 检验
- 验收标准必须用 Given/When/Then
- 每个 Story 必须可追溯到 PRD 功能点编号
- 每个 Story 必须补充独立价值、独立验收方式、依赖、回滚/降级说明
- 不生成纯技术 Story

执行步骤维持原有逻辑并增强：
1. PRD 解析
2. Epic 映射
3. Story 分解
4. 追溯性检查
5. INVEST 验证
6. 独立交付切片检查
7. 用户确认
8. 保存 Story 产出
9. 询问是否生成 UAT 验收包

---

## UAT 验收包

Story 保存后，使用 `AskUserQuestion` 询问是否生成 UAT 验收包：
- **生成 UAT 验收包（推荐）** — 从 Story 验收标准、指标、NFR、治理要求生成验收清单
- **暂不生成** — `uat_status` 保持 `pending`
- **记录豁免** — 说明为什么本次不需要 UAT，写入 `uat_status: waived`

生成时使用 `assets/uat-pack-template.md`，保存到：
`{需求目录}/stories/uat-pack-{日期}.md`

UAT 包至少包含：
- UAT 范围和入口条件
- Story → UAT 用例映射
- 正向 / 异常 / 边界 / 逆向验收场景
- NFR / 治理验收项（如已做相关维度）
- 风险、豁免和 Go/No-Go 记录

---

## 保存路径与状态更新

保存到：
`{需求目录}/stories/stories-{日期}.md`

同步更新：
- `completed_steps` 追加 `story-decompose`
- `artifact_paths.stories`
- `artifact_paths.uat_pack`（如生成）
- `slice_status: ready`（全部 Story 独立切片检查通过）或 `partial`（存在切片风险）
- `uat_status: ready`（已生成）、`waived`（用户确认豁免）或 `pending`（暂不生成）
- `next_recommended_step`

推荐逻辑：
- 若已选 `success-metrics` 未完成 → 推荐 `define-success`
- 若已选 `roadmap` 未完成 → 推荐 `portfolio-roadmap`
- 否则 → `done-for-now`

<IMPORTANT>
本技能是可选维度，不再默认属于每个需求。
</IMPORTANT>