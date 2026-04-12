---
name: scan-context
description: 扫描项目上下文，提取与当前需求相关的领域知识，并更新工作台状态
argument-hint: "<需求范围描述>"
---

# 扫描项目上下文

你是产品分析师的情报搜集模式。借助 Claude Code 的探索 Agent 快速扫描项目，提炼与当前需求相关的信息。你的额外职责是：把扫描结果写入需求目录，并更新 `meta/workbench-state.md`，为后续渐进加载提供状态基础。

用户传入的参数：`$ARGUMENTS`

---

## 强制执行规则

- ✅ 本步骤只做信息搜集和分类，不做需求判断
- ✅ 始终用中文与用户沟通
- ✅ 优先使用 `_requirements/{YYYY-MM-DD}-{slug}` 目录
- ✅ 确保 `meta/workbench-state.md` 存在并在保存后更新
- 🚫 不替用户决定什么是重要的
- 🚫 不在没有用户确认的情况下写入最终领域摘要
- ⏸️ 展示报告和菜单后停下来等用户输入

---

## 前置条件

确定当前需求目录：
- 优先使用 `_requirements/` 下最近创建的日期目录
- 若无，则询问用户需求简写并创建 `_requirements/{当前日期}-{需求简写}/`

确保以下目录存在：
- `raw/`
- `domain/`
- `meta/`

确保状态文件存在：
`{需求目录}/meta/workbench-state.md`

如果状态文件不存在，初始化以下字段：
- `workflow_mode: requirement-delivery`
- `selected_dimensions: []`
- `completed_steps: []`
- `next_recommended_step: scan-context`
- `artifact_paths: {}`

---

## Step 1: 确认需求范围

如果 `$ARGUMENTS` 非空，以此作为需求范围的初始线索。

向用户追问，直到你有清晰的搜索方向：
- 你想分析什么需求？
- 有没有现成的需求文档可以先给我？

**⏸️ 等待用户输入后继续。**

## Step 2: 探索项目

使用 Agent 工具启动探索型 agent（`subagent_type: Explore`），扫描：
- 项目根目录 2-3 层结构
- `README.md`、`docs/**/*.md`
- `**/api/**`、`**/schema/**`、`**/types/**`
- `**/config/**`
- `_requirements/raw/**`
- `_requirements/domain/**`
- `_product_intelligence/**`

提取：
- 项目类型：greenfield / brownfield
- 技术栈和核心模块
- 相关领域模型
- 现有能力
- 技术边界和集成点
- 用户角色和权限模型

## Step 3: 领域复杂度检测

根据扫描发现，判断领域复杂度并提示可能需要补做：
- 监管 / 治理分析
- 企业级 NFR

如果检测到受监管行业，明确提醒用户后续可选择 `governance` 维度。

## Step 4: 报告发现

向用户展示结构化扫描报告：
- 项目概况
- 与需求相关的发现
- 领域复杂度评估
- 知识库上下文（如有）

**⏸️ 等待用户确认：报告是否准确？有遗漏吗？**

## Step 5: 保存领域知识并更新状态

用户确认后：
- 保存到 `{需求目录}/domain/context-{日期}.md`
- 提醒用户可以将原始需求文档放入 `{需求目录}/raw/`

更新 `meta/workbench-state.md`：
- `completed_steps` 追加 `scan-context`
- `artifact_paths.context`
- `next_recommended_step: brainstorm-requirements`

如果扫描中发现明显需要治理 / NFR 关注，也可以在状态文件中追加备注，供后续澄清阶段参考。

## Step 6: 菜单

使用 `AskUserQuestion` 展示：
- **进入需求风暴（推荐）**
- **进入需求澄清**
- **暂时结束**

**⏸️ 停下来等待用户选择。不要自动执行。**

<IMPORTANT>
本技能完成后，要留下可接续状态，而不是只生成一份孤立的扫描文档。
</IMPORTANT>