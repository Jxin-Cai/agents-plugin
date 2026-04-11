---
name: e2e
description: E2E 测试入口——支持设计模式（新建测试的六阶段流水线）和回归模式（执行已有脚本的轻量批量流程）
argument-hint: "<被测功能或应用描述>"
allowed-tools: Read, Write, Glob, Bash(mkdir*), AskUserQuestion, Skill
---

# E2E 测试入口

用户传入的参数：`$ARGUMENTS`

---

## 模式路由

根据用户输入自动判断模式，或询问用户：

- 输入明确指向新测试设计（"测试一下支付流程"、"验证新功能"、"帮我测"）→ **设计模式**
- 输入明确指向回归（"跑回归"、"run smoke"、"执行 user-auth 的脚本"）→ 调用 `run-suite` skill
- 输入明确指向修复（"脚本跑不过了"、"fix ts-001"）→ 调用 `fix-script` skill
- 输入明确指向影响分析（"这次改动影响什么"、"哪些测试要跑"）→ 调用 `impact-analysis` skill
- 输入不明确 → 使用 `AskUserQuestion` 询问

---

以下为**设计模式**的完整流程。

## 上下文管理纪律

1. **任务落盘**：`task/task.md` 是一级输入；`task/index.md` 是唯一状态文件（格式见 `references/index-template.md`）
2. **阶段摘要**：每阶段完成后按 `references/stage-summary-templates.md` 写摘要
3. **共享资产优先**：先检索 `_shared/`、`asset-catalog.md`、`registry/`
4. **从文件读上下文**：每阶段开始时从文件读取前置摘要，不依赖对话记忆
5. **重型走 subagent**：代码扫描（scan-context）、脚本生成（test-automation-builder）走 subagent
6. **逐阶段停顿**：等用户确认，不自动跳步
7. **quality-ledger 是缓存**：存在时加速，缺失不阻塞

---

## Step 0: 初始化与断点恢复

1. 从 `$ARGUMENTS` 提取测试目标，生成 domain 名（kebab-case），用 `AskUserQuestion` 确认
2. 创建工作目录 `.e2e-tests/{domain}/` 及子目录（task/context/scenarios/prep/automation/fixtures/reports/evidence）
3. 确保共享目录和全局文件存在（`_shared/`、`registry/index.yaml`、`asset-catalog.md`、`quality-ledger.md`），缺失则初始化
4. 如果 `.e2e-tests/env/` 不存在，创建目录并按 `references/env-config-template.md` 生成 `env.yaml` 模板，提示用户配置环境信息
5. 按 `references/index-template.md` 初始化 `task/index.md`（如不存在）
6. **进度推断**——以 index.md frontmatter + 实际文件产物为准：
   - 无 task.md → Step 1
   - 有 task 无上下文摘要 → Step 2
   - 有 task + 上下文但无剧本 → Step 3
   - 有剧本无 prep → Step 4
   - 有 prep 无报告 → Step 5
   - 有报告建议沉淀但无脚本 → Step 6
   - 全齐 → 已完成，可选重跑/补测/新建
7. 扫描共享资产，向用户报告可复用内容
8. 用 `AskUserQuestion` 确认接续阶段

---

## Step 1-6: 设计模式流水线

> **条件加载**：进入 Step 1 前，读取 `references/design-mode-steps.md` 获取各阶段的完整执行指令（入口读取、产物要求、摘要落盘、index.md 更新、用户确认规则）。以下表格仅为速查概览。

| Step | 调用 Skill | 入口读取 | 完成标志 | 摘要 |
|------|-----------|---------|---------|------|
| 1 澄清 | `clarify-scope` | index.md, task.md(如有) | task.md 生成且用户确认 | stage-1-summary.md |
| 2 扫描 | `scan-context` | task.md, index.md, stage-1-summary | context/ 下有摘要且用户确认 | stage-2-summary.md |
| 3 剧本 | `test-scenario-gen` | task.md, index.md, stage-1/2-summary | scenarios/TS-*.md 生成且用户确认 | stage-3-summary.md |
| 4 准备 | `test-prep` | task.md, index.md, stage-3-summary | prep/TP-*.md 生成，readiness 明确 | stage-4-summary.md |
| 5 执行 | `test-runner` | task.md, index.md, stage-3/4-summary | reports/ 下有报告 | — |
| 6 沉淀 | `test-automation-builder` | task.md, index.md, stage-3/4-summary, 报告 | 脚本生成，registry 更新 | — |

每个 Step 完成后：
1. 写阶段摘要（Step 1-4）
2. 更新 `task/index.md` 的 frontmatter 和产物区块
3. `AskUserQuestion` 确认后进入下一步

---

## 接续规则

1. **接续基于产物，不基于记忆**
2. **frontmatter 与实际产物冲突时，以产物为准**
3. **缺必要字段停在该阶段补齐，不跳步**
4. **允许回退重做，保留已有文档，在 index.md 修正记录中标注**
5. **不擅自删除旧产物**

<IMPORTANT>
每阶段完成后等用户确认。没有 task.md 不进入后续阶段。
</IMPORTANT>
