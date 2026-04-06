---
name: aa
description: 无障碍审计完整流程——按顺序执行 WCAG 审计、辅助技术测试、合规报告生成
argument-hint: "<审计目标描述（页面URL、组件名称或功能模块）>"
---

# 无障碍审计完整流程

入口编排技能，串联三个阶段完成从 WCAG 审计到合规报告的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取审计目标描述，生成简短英文缩写（2-4 词，连字符连接，如 `login-page`、`checkout-flow`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称
3. 设定工作目录：`_accessibility/{当前日期}-{任务简写}/`（如 `_accessibility/2026-04-06-login-page/`）
4. 创建子目录：`context/`、`wcag/`、`assistive-tech/`、`reports/`
5. 扫描 `_accessibility/` 下已有的目录，向用户简要报告

---

## Step 1: WCAG 审计

调用 `/wcag-audit $ARGUMENTS`

按 POUR 四原则对目标页面/组件进行逐项审计，生成问题清单。

**阶段完成标志：** `{工作目录}/wcag/wcag-audit-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充审计范围 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 辅助技术测试

调用 `/assistive-tech-test`

基于 WCAG 审计的发现，进行屏幕阅读器、键盘导航等辅助技术实测。

**阶段完成标志：** `{工作目录}/assistive-tech/at-test-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充测试场景 / 回到 WCAG 审计）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 合规报告

调用 `/compliance-report`

将审计和测试的发现整合为 VPAT/ACR 格式的合规性报告。

**阶段完成标志：** `{工作目录}/reports/compliance-report-*.md` 已生成。

报告保存后，向用户展示文件的 **绝对路径**（如 `/Users/xxx/project/_accessibility/2026-04-06-login-page/reports/compliance-report-2026-04-06.md`），以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
