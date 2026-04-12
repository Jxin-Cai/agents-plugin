---
name: cr
description: 代码审查编排器——按意图路由到安全审查、质量审计、重构建议或完整流程
argument-hint: "<审查目标描述，如 PR 链接、文件路径或功能模块名>"
allowed-tools: ["Read", "Write", "Glob", "Bash", "AskUserQuestion"]
---

# 代码审查编排器

意图路由入口，根据用户需求分流到不同 workflow。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 意图识别

Read `references/workflow-playbook.md`

根据 `$ARGUMENTS` 和 playbook 中的路由矩阵匹配 workflow：

| workflow | 触发关键词 | 执行内容 |
|----------|-----------|---------|
| `full-review` | "完整审查"、"全面审查"、无明确意图 | security -> quality -> refactor 全链路 |
| `security-focus` | "安全"、"漏洞"、"OWASP" | 路由到 `/security-review` |
| `quality-focus` | "质量"、"复杂度"、"坏味道" | 路由到 `/quality-audit` |
| `refactor-focus` | "重构"、"优化"、"改进代码" | 路由到 `/refactor-suggestions` |
| `quick-scan` | "快速"、"扫一下"、"概览" | 编排器内轻量级全维度速览 |
| `custom` | 用户明确指定组合 | 按用户选择组合执行 |

**意图不明确时**，用 `AskUserQuestion` 向用户展示 workflow 选项让其选择。

---

## Step 1: 初始化工作区

1. 从 `$ARGUMENTS` 提取审查目标，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认任务简写名
3. 创建工作目录 `_code-review/{日期}-{简写}/` 及子目录 `context/` `security/` `quality/` `refactoring/` `meta/`
4. Read `references/review-state-template.md`，初始化 `meta/review-state.md`（写入 workflow 类型和初始状态）
5. 扫描 `_code-review/` 下已有目录，向用户简报
6. 确定审查范围（PR 链接提取变更文件 / 文件路径扫描 / 模块名定位），保存到 `context/scope.md`

---

## Step 2: 执行 Workflow

每个阶段入口重新 Read `meta/review-state.md`，完成后更新状态文件。

### full-review

| 阶段 | 调用 | 完成标志 | 门控选项 |
|------|------|---------|---------|
| 安全审查 | `/security-review $ARGUMENTS` | `security/security-report-*.md` | 继续 / 深入 / 结束 |
| 质量审计 | `/quality-audit $ARGUMENTS` | `quality/quality-report-*.md` | 继续 / 深入 / 回退 |
| 重构建议 | `/refactor-suggestions $ARGUMENTS` | `refactoring/refactor-report-*.md` | 报告 / 深入 / 结束 |

每个阶段完成后，用 `AskUserQuestion` 展示产出摘要和选项，等待用户确认。

### single-focus（security-focus / quality-focus / refactor-focus）

直接路由到对应子技能，编排器只做初始化和收尾。

### quick-scan

编排器内执行轻量级全维度速览：

1. 安全速览：硬编码凭据、明显注入、危险函数（约 3 分钟）
2. 质量速览：文件大小、最高圈复杂度、重复代码块（约 3 分钟）
3. 重构速览：标记最突出的 2-3 个坏味道（约 3 分钟）

生成精简报告到 `meta/quick-scan-{日期}.md`。

---

## Step 3: 综合报告与收尾

Read `references/report-template.md`

汇总各阶段产出，生成综合审查报告。更新状态文件 `workflow_status = completed`。

使用 `AskUserQuestion` 展示完成摘要：

> 审查摘要：安全问题 [N] 个（Blocker [a] / Suggestion [b]），质量问题 [M] 个，重构建议 [K] 个。

选项：生成综合报告 / 深入某个问题 / 结束审查

---

## 断点恢复

当用户中途返回或继续已有审查时：

1. 检查 `_code-review/` 是否有未完成审查目录
2. Read `meta/review-state.md` 获取进度
3. 检查各阶段产出文件存在性（产出文件优先于状态记录）
4. 使用 `AskUserQuestion` 展示恢复选项：从断点继续 / 重新开始

---

<IMPORTANT>
## 质量硬门控（不可绕过）

1. 每阶段完成后必须通过 `AskUserQuestion` 获得用户确认才能继续，不得自动推进
2. Critical 级安全问题必须在摘要中醒目标注，不可隐藏或降级
3. 不得跳过已选 workflow 中的任何阶段（用户主动要求除外）
4. 每个阶段入口重读状态文件 `meta/review-state.md`，防止状态漂移
5. 产出文件与状态文件冲突时，以产出文件为准
</IMPORTANT>
