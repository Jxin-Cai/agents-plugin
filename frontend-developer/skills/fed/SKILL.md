---
name: fed
description: 前端开发专家完整工作流——按顺序执行组件架构审查、响应式审计、性能检查
argument-hint: "<任务描述或目标组件/页面路径>"
---

# 前端审查完整流程

入口编排技能，串联三个阶段完成从项目上下文扫描到完整前端质量审查报告的完整流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `dashboard-refactor`、`login-page`）
2. 使用 `AskUserQuestion` 工具向用户确认任务简写名称
3. 设定工作目录：`_frontend-review/{当前日期}-{任务简写}/`（如 `_frontend-review/2026-04-06-dashboard-refactor/`）
4. 创建子目录：`context/`、`components/`、`responsive/`、`performance/`
5. 扫描 `_frontend-review/` 下已有的目录，向用户简要报告
6. 快速扫描项目根目录的 `package.json`、`tsconfig.json`、构建配置（vite.config / next.config / webpack.config 等），提取技术栈信息保存到 `context/tech-stack.md`

---

## Step 1: 组件架构审查

调用 `/component-review $ARGUMENTS`

审查目标组件/页面的组件设计、Props 接口、状态管理、复用性和代码质量。

**阶段完成标志：** `{工作目录}/components/component-review-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 重新审查 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 响应式审计

调用 `/responsive-audit $ARGUMENTS`

检查断点策略、布局弹性、触控适配、图片响应式处理和多端一致性。

**阶段完成标志：** `{工作目录}/responsive/responsive-audit-*.md` 已生成。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 重新审计 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 性能检查

调用 `/performance-check $ARGUMENTS`

Core Web Vitals 合规检测、资源加载优化分析、渲染性能和 JavaScript 执行效率审查。

**阶段完成标志：** `{工作目录}/performance/performance-check-*.md` 已生成。

审查报告保存后，向用户展示文件的 **绝对路径**，以便用户直接点击打开。

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
