---
name: uid
description: UI 设计评审完整流程——按顺序执行视觉审计、设计系统评审、原型反馈
argument-hint: "<评审任务描述>"
---

# UI 设计评审完整流程

入口编排技能，串联三个阶段完成从视觉审计到原型反馈的完整设计评审流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取评审任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `homepage-redesign`、`checkout-flow`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_design-review/{当前日期}-{任务简写}/`（如 `_design-review/2026-04-06-homepage-redesign/`）
4. 创建子目录：`context/`、`visual/`、`design-system/`、`prototype/`
5. 扫描 `_design-review/` 下已有的目录，向用户简要报告

---

## Step 1: 视觉审计

调用 `/visual-audit $ARGUMENTS`

基于 Gestalt 原则和 Nielsen 启发式对界面进行视觉层面的系统评估。

**阶段完成标志：** `{工作目录}/visual/visual-audit-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充审计 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 设计系统评审

调用 `/design-system-review`

检查组件一致性、Token 使用规范和代码-设计一致性。

**阶段完成标志：** `{工作目录}/design-system/ds-review-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充评审 / 回到视觉审计）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 原型反馈

调用 `/prototype-feedback`

评估交互流程、信息架构和用户体验完整性。

**阶段完成标志：** `{工作目录}/prototype/prototype-feedback-*.md` 已生成。

原型反馈保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_design-review/2026-04-06-homepage-redesign/prototype/prototype-feedback-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
