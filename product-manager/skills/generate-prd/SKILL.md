---
name: generate-prd
description: 将澄清与已选分析维度的成果收敛成结构化 PRD 文档
argument-hint: "<项目名称或需求目录>"
---

# 生成 PRD

你是产品分析师的产出模式——把澄清阶段与其他已选分析维度的成果，收敛成一份高信息密度的 PRD。你不再默认 PRD 是唯一中心文档，而是把它作为 **本次被选择的一个交付维度**。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

使用 Read 工具加载以下引用文件，严格遵守其中规则：

- `references/prd-writing-guide.md` — PRD 写作规范
- `assets/prd-template.md` — PRD 输出模板

---

## 强制执行规则

- ✅ 始终用中文撰写 PRD
- ✅ 严格使用 `assets/prd-template.md` 的结构
- ✅ 先读取 `meta/workbench-state.md`，确认本次确实选择了 `prd`
- ✅ 如果用户已做 discovery / NFR / governance，要把相关摘要纳入 PRD
- ✅ 运行时状态不写进 PRD 正文，只写入 frontmatter 的契约字段
- 🚫 用户未选择 `prd` 时，不要擅自生成 PRD
- ⏸️ 生成后先展示给用户确认，再保存

---

## 前置条件

确定当前需求目录：优先使用 `.product-manager/requirements/` 下最近创建的日期目录。

加载以下上下文（按优先级）：
1. `{需求目录}/meta/workbench-state.md` — 必须，确认维度与已完成步骤
2. `{需求目录}/domain/clarified-*.md` — 最优先
3. `{需求目录}/domain/brainstorm-*.md`
4. `{需求目录}/domain/context-*.md`
5. `{需求目录}/discovery/discovery-*.md` — 如已做 discovery
6. `{需求目录}/nfr/nfr-*.md` — 如已做 enterprise-nfr
7. `{需求目录}/governance/governance-*.md` — 如已做 governance
8. `{需求目录}/raw/**`
9. `.product-manager/intelligence/domain-glossary.md`
10. `.product-manager/intelligence/product-context.md`
11. 当前对话中的需求讨论

如果 `selected_dimensions` 不包含 `prd`：
- 向用户说明 PRD 不在本次已选维度中
- 询问是否要补选 `prd`
- 未得到确认前不要继续

---

## Step 1: 汇总需求素材

从所有来源汇总：
- 目标用户和角色列表
- 核心价值和要解决的问题
- 功能模块和功能点清单
- 三条链路与边界条件
- 优先级标注
- 领域复杂度与治理要求
- NFR 约束
- discovery 结论（如有）
- 开放问题

如果关键信息缺失，向用户追问后再继续。不猜测。

## Step 2: 生成 PRD 文档

按模板生成：
- 使用统一 frontmatter v2
- `selected_dimensions` 填写状态文件中用户确认的维度
- `nfr_profile` 从 NFR 文档或澄清结果提取
- `compliance_profile` 从治理文档或扫描结果提取

正文生成规则：
- 功能清单必须覆盖七列
- P0 功能的异常和逆向路径不能留空
- 补充分析摘要章节按已选维度填写：
  - 做了 discovery → 填写问题 / 假设 / 实验 / 结论
  - 做了 enterprise-nfr → 填写 NFR 摘要
  - 做了 governance → 填写治理 / 合规摘要
- 后续 PM 工作章节根据 `selected_dimensions` 标记待做 / 已完成 / 未选择

## Step 3: 质量自检

严格检查：
- 所有用户角色都有对应功能点
- P0 功能的异常 / 逆向 / 边界信息完整
- frontmatter 字段与契约一致
- `requirement_dir` 使用 `.product-manager/requirements/{YYYY-MM-DD}-{slug}`
- 已选分析维度与正文摘要一致
- 没有将运行时状态写成正文内容

## Step 4: 知识库一致性检查

如果有术语表：
- 检查术语是否一致
- 标出候选新术语供用户确认是否写入知识库

## Step 5: 用户确认

向用户展示 PRD 摘要与文档统计：
- 功能模块数
- 功能点数
- 已纳入的分析维度
- 开放问题数
- frontmatter 关键信息

使用 `AskUserQuestion` 询问：
- 保存 PRD
- 修改 PRD

**⏸️ 等待用户确认。**

## Step 6: 保存 PRD 并更新状态

保存到：
`{需求目录}/prd/prd-{项目名}-{日期}.md`

同时更新 `meta/workbench-state.md`：
- `completed_steps` 追加 `generate-prd`
- `artifact_paths.prd`
- `next_recommended_step`

推荐逻辑：
- 如果选了 `story` 且未完成 → 推荐 `story-decompose`
- 如果选了 `success-metrics` 且未完成 → 推荐 `define-success`
- 如果选了 `roadmap` 且未完成 → 推荐 `portfolio-roadmap`
- 否则 → `done-for-now`

保存后展示文件绝对路径，并只展示与已选维度相关的后续建议。

---

## 成功标准

### ✅ 成功
- 仅在用户已选择 `prd` 的前提下生成 PRD
- PRD frontmatter 与统一契约一致
- 能吸纳 discovery / NFR / governance 的摘要
- 仅展示与已选维度相关的下一步
- 状态文件已同步更新

### ❌ 失败
- 用户未选 `prd` 却自动生成 PRD
- frontmatter 仍使用旧字段体系
- 示例路径仍混用旧式无日期目录写法
- 状态文件未更新

<IMPORTANT>
PRD 是可选维度，不是所有需求型工作的默认必经步骤。
</IMPORTANT>