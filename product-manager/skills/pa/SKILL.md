---
name: pa
description: 产品需求分析完整流程——按顺序执行扫描、风暴、澄清、PRD 生成
argument-hint: "<需求描述>"
---

# 产品分析完整流程

入口编排技能，串联四个阶段完成从需求发现到 PRD 产出的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取需求描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `user-auth`、`inventory-mgmt`）
2. 使用 `AskUserQuestion` 工具向用户确认需求简写名称，提供你建议的缩写作为选项
3. 设定需求目录：`_requirements/{当前日期}-{需求简写}/`（如 `_requirements/2026-04-06-user-auth/`）
4. 创建子目录：`raw/`、`domain/`、`prd/`
5. 扫描 `_requirements/` 下已有的需求目录，向用户简要报告

---

## Step 1: 扫描上下文

调用 `/scan-context $ARGUMENTS`

扫描项目代码和文档，提取与需求相关的领域知识。

**阶段完成标志：** `{需求目录}/domain/context-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 重新扫描 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 需求风暴

调用 `/brainstorm-requirements`

基于扫描上下文的产出，进行收敛式需求发散。

**阶段完成标志：** `{需求目录}/domain/brainstorm-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 再来一轮风暴 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 需求澄清

调用 `/clarify-requirements`

逐项追问边界条件、异常路径和逆向机制。

**阶段完成标志：** `{需求目录}/domain/clarified-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续生成 PRD / 再来一轮澄清 / 回到需求风暴）。

**⏸️ 等待用户选择后继续。**

---

## Step 4: 生成 PRD

调用 `/generate-prd`

将完善的需求写成极简 PRD 文档。

**阶段完成标志：** `{需求目录}/prd/prd-*.md` 已生成。

PRD 保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_requirements/2026-04-06-user-auth/prd/prd-user-auth-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
