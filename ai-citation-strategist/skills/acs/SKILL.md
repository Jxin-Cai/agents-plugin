---
name: acs
description: AI 引用优化完整工作流——按顺序执行引用审计、丢失查询分析、修复方案生成
argument-hint: "<品牌/产品描述>"
---

# AI 引用优化完整流程

入口编排技能，串联三个阶段完成从引用审计到修复方案的完整 AEO/GEO 优化流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取品牌/产品信息，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `saas-crm`、`ecommerce-shopify`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_ai-citation/{当前日期}-{任务简写}/`（如 `_ai-citation/2026-04-07-saas-crm/`）
4. 创建子目录：`context/`、`audit/`、`analysis/`、`fix-packs/`
5. 扫描 `_ai-citation/` 下已有的任务目录，向用户简要报告
6. 引导用户确认以下基础信息并保存到 `{工作目录}/context/brand-profile.md`：
   - **品牌名称**：正式品牌名和常见别名
   - **主域名**：品牌官网地址
   - **产品类别**：所属行业/品类
   - **目标受众**：核心用户画像
   - **主要竞品**：3-5 个直接竞品

---

## Step 1: 引用审计

调用 `/citation-audit $ARGUMENTS`

在 ChatGPT、Claude、Gemini、Perplexity 等平台进行多维度引用检测和评分。

**阶段完成标志：** `{工作目录}/audit/citation-audit-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充引用审计 / 结束流程）。

**暂停 等待用户选择后继续。**

---

## Step 2: 丢失查询分析

调用 `/lost-prompt-analysis`

从审计结果中筛选品牌缺失的查询，分析竞品为什么赢。

**阶段完成标志：** `{工作目录}/analysis/lost-prompt-analysis-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充丢失分析 / 回到引用审计）。

**暂停 等待用户选择后继续。**

---

## Step 3: 修复方案生成

调用 `/fix-pack-generation`

基于审计和分析结果，生成优先级排序的修复计划和实施清单。

**阶段完成标志：** `{工作目录}/fix-packs/fix-pack-*.md` 已生成。

报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
