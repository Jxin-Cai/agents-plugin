---
name: cr
description: 代码审查完整流程——按顺序执行安全审查、质量审计、重构建议
argument-hint: "<审查目标描述，如 PR 链接、文件路径或功能模块名>"
---

# 代码审查完整流程

入口编排技能，串联三个阶段完成从安全审查到重构建议的完整代码审查流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取审查目标描述，生成一个简短的英文缩写（2-4 个词，用连字符连接，如 `user-auth-api`、`payment-module`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称，提供你建议的缩写作为选项
3. 设定工作目录：`_code-review/{当前日期}-{任务简写}/`（如 `_code-review/2026-04-06-user-auth-api/`）
4. 创建子目录：`context/`、`security/`、`quality/`、`refactoring/`
5. 扫描 `_code-review/` 下已有的审查目录，向用户简要报告
6. 确定审查范围：
   - 如果用户提供了 PR 链接，提取变更文件列表
   - 如果用户提供了文件路径或目录，扫描目标文件
   - 如果用户提供了功能模块名，定位相关代码文件
7. 将审查范围摘要保存到 `context/scope.md`

---

## Step 1: 安全审查

调用 `/security-review $ARGUMENTS`

基于 OWASP Top 10 对目标代码进行安全漏洞扫描和风险评估。

**阶段完成标志：** `{工作目录}/security/security-report-{日期}.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 深入某个安全问题 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 质量审计

调用 `/quality-audit $ARGUMENTS`

评估代码质量指标，识别复杂度、重复度、耦合度等方面的问题。

**阶段完成标志：** `{工作目录}/quality/quality-report-{日期}.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 深入某个质量问题 / 回到安全审查）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 重构建议

调用 `/refactor-suggestions $ARGUMENTS`

识别代码坏味道，提供具体的重构方案和影响评估。

**阶段完成标志：** `{工作目录}/refactoring/refactor-report-{日期}.md` 已生成。

报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

使用 `AskUserQuestion` 工具向用户展示完成摘要和后续选项：

审查摘要：安全问题 [N] 个（Blocker [a] / Suggestion [b]），质量问题 [M] 个，重构建议 [K] 个。

- **生成综合审查报告（推荐）** — 合并三个阶段的产出为一份完整报告
- **深入某个具体问题** — 选择一个问题进行详细分析
- **结束审查** — 当前审查已完成

**⏸️ 等待用户选择后继续。**

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
