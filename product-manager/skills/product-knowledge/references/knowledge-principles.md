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

## 各技能协作

| 技能 | 读取 | 写入 |
|------|------|------|
| scan-context | context、glossary、decisions | glossary（新术语） |
| brainstorm | patterns、decisions | — |
| clarify | decisions | decisions（新决策） |
| generate-prd | glossary | glossary、context |
| post-launch-review | 全部 | patterns、decisions |
| product-knowledge | 全部 | 全部 |