---
name: pa
description: 产品分析完整流程——按顺序执行扫描、风暴、澄清、PRD 生成
argument-hint: "<需求描述>"
---

# 产品分析完整流程

入口编排技能，串联四个阶段完成从需求发现到 PRD 产出的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 检查 `_requirements/` 目录，不存在则创建 `_requirements/raw/`、`_requirements/domain/`、`_requirements/prd/`
2. 扫描 `_requirements/` 下已有的文档，向用户简要报告
3. 如果 `$ARGUMENTS` 非空，作为需求描述传递给后续阶段

---

## Step 1: 扫描上下文

调用 `/scan-context $ARGUMENTS`

扫描项目代码和文档，提取与需求相关的领域知识。

**阶段完成标志：** `_requirements/domain/context-*.md` 已生成。

向用户确认是否进入下一阶段。

**⏸️ 等待用户确认后继续。**

---

## Step 2: 需求风暴

调用 `/brainstorm-requirements`

基于扫描上下文的产出，进行收敛式需求发散。

**阶段完成标志：** `_requirements/domain/brainstorm-*.md` 已生成。

向用户确认是否进入下一阶段。

**⏸️ 等待用户确认后继续。**

---

## Step 3: 需求澄清

调用 `/clarify-requirements`

逐项追问边界条件、异常路径和逆向机制。

**阶段完成标志：** `_requirements/domain/clarified-*.md` 已生成。

向用户确认是否进入下一阶段。

**⏸️ 等待用户确认后继续。**

---

## Step 4: 生成 PRD

调用 `/generate-prd`

将完善的需求写成极简 PRD 文档。

**阶段完成标志：** `_requirements/prd/prd-*.md` 已生成。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
