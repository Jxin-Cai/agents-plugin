---
name: bg
description: 品牌守护者完整工作流——按顺序执行品牌一致性审计、语气风格审查、视觉识别检查
argument-hint: "<品牌审查任务描述>"
---

# 品牌守护者完整流程

入口编排技能，串联三个阶段完成从品牌资产盘点到全面审查报告的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `website-rebrand`、`app-launch-review`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_brand-review/{当前日期}-{任务简写}/`（如 `_brand-review/2026-04-06-website-rebrand/`）
4. 创建子目录：`context/`、`consistency/`、`voice-tone/`、`visual/`
5. 扫描 `_brand-review/` 下已有的目录，向用户简要报告

---

## Step 1: 品牌一致性审计

调用 `/brand-consistency-audit $ARGUMENTS`

全面盘点品牌资产，逐项检查跨渠道一致性，生成偏差报告和评分表。

**阶段完成标志：** `{工作目录}/consistency/audit-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充审计 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 语气风格审查

调用 `/voice-tone-review $ARGUMENTS`

基于一致性审计的发现，深入审查内容的品牌声音和语气一致性。

**阶段完成标志：** `{工作目录}/voice-tone/review-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 再审查其他内容 / 回到一致性审计）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 视觉识别检查

调用 `/visual-identity-check $ARGUMENTS`

检查视觉元素是否符合品牌视觉规范，输出合规报告和改进建议。

**阶段完成标志：** `{工作目录}/visual/check-*.md` 已生成。

审查报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
