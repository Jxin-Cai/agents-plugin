# 知识管理原则

## 筛选标准

**记录：** 影响未来多个需求周期的决策、反复出现的需求模式（≥2 次）、团队共识的术语定义、产品核心约束、"下次别再踩"的坑。

**不记录：** 临时讨论、可从代码/Git 读取的细节、个人偏好、一次性任务进度。

## 写入规则

| 文件 | 方式 | 原因 |
|------|------|------|
| `decision-journal.md` | 追加 | 历史不可篡改，错误标记"已废弃" |
| `domain-glossary.md` | 覆盖更新 | 术语保持最新，旧版由 Git 追溯 |
| `patterns.md` | 追加 | 模式持续丰富 |
| `product-context.md` | 覆盖更新 | 始终反映当前状态 |
| `changelog.md` | 追加 | 只增不减 |

编号：决策 `D{3位}`，模式 `PT{3位}`，自动递增。  
变更日志：`- [{日期}] {操作类型}: {摘要} — by {来源}`

## 容量管理

- 决策 >100 条 → 提醒归档旧条目
- 术语 >200 个 → 提醒清理过时项
- 模式 >50 个 → 提醒合并相似项

## 质量标准

**决策：** 回答三件事——做了什么决定、为什么、放弃了什么。  
**术语：** 在本产品上下文中唯一明确，标注别名。  
**模式：** 可复用、有陷阱记录、有参考实例。

## 归档回流标准

规格进入归档前必须满足：
- 已有上线复盘，或用户明确说明本需求不再继续推进
- 复盘中产生的决策、术语、模式、产品约束已被逐项确认写入或跳过
- 跳过的候选项必须记录原因，避免未来重复讨论
- 状态文件可更新为 `spec_state: retired`

最小回流集合：
1. 本次验证过且未来会复用的产品决策
2. 影响多个需求的术语或指标口径
3. 可复用的需求模式和常见陷阱
4. 产品长期约束或治理要求

归档后，需求目录保留为事实来源；知识库只沉淀可复用结论，不复制完整 PRD / Story / UAT 内容。

## 各技能协作

| 技能 | 读取 | 写入 |
|------|------|------|
| scan-context | context、glossary、decisions | glossary（新术语） |
| brainstorm | patterns、decisions | — |
| clarify | decisions | decisions（新决策） |
| generate-prd | glossary | glossary、context |
| post-launch-review | 全部 | 知识回流候选（pending） |
| product-knowledge | 全部 | 全部 |
| product-knowledge archive-spec | review、PRD、stories、UAT、jira-sync | decisions、glossary、patterns、context、archive 状态 |