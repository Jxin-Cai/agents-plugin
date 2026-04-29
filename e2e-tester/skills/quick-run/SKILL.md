---
name: quick-run
description: 快速浏览器验收——贴 URL + 验收步骤即可直接执行，跳过完整设计流程。适用于"帮我快速验一下"、"用浏览器跑这几步"等轻量需求。
argument-hint: "<URL + 验收步骤>"
allowed-tools: Read, Write, Glob, Bash(mkdir*), AskUserQuestion, Skill
---

# 快速浏览器验收

用户传入的参数：`$ARGUMENTS`

> **核心理念**：跳过设计仪式，直达浏览器执行。适用于目标明确、不需要完整风险分析的快速验证场景。

---

## Step 0: 解析输入

从 `$ARGUMENTS` 提取：
- **目标 URL**：如果用户提供了 URL，直接使用；否则检查 `.e2e-tests/shared/env/` 下已有环境配置，推荐选择
- **验收步骤**：用户贴的自然语言或 Markdown checklist，保留原文
- **隐含参数自动推断**：
  - workflow = `express`
  - evidence_level = `light`
  - acceptance_source = `user-text` 或 `markdown`（根据输入格式判断）
  - export_intent = `suggest`（成功后建议沉淀，但不强制）

如果 URL 和验收步骤都缺失，用 **单次** `AskUserQuestion` 补齐（一次问完，不分多轮）：
- 目标 URL
- 验收步骤（支持粘贴多行）

## Step 1: 最小化落盘

1. 生成 scenario-slug（从 URL path 或验收步骤关键词自动推导，不问用户确认）
2. 生成 run-slug = `quick-{HHmm}`
3. 创建最小目录结构：
   ```bash
   mkdir -p .e2e-tests/scenarios/{scenario}/runs/{date}-{run}/evidence
   mkdir -p .e2e-tests/scenarios/{scenario}/runs/{date}-{run}/reports
   ```
4. 写入精简 `task.md`（只含 URL、验收步骤原文、evidence_level=light）
5. 写入精简 `index.md`（frontmatter 只填必要字段，正文留空）
6. 检查 `.e2e-tests/shared/env/` 是否有匹配的环境配置：
   - 有 → 读取并使用
   - 无 → 如果用户给了 URL，自动创建最小环境配置（只含 base_url + name）；同时检查 session-start 发现的项目环境线索（package.json proxy、.env BASE_URL、playwright.config baseURL），自动补充 api_base_url 和 blocked_scripts
7. 更新 `.e2e-tests/shared/knowledge-index.md`「环境配置」和「活跃剧本」表

## Step 2: 直达 test-runner

调用 `test-runner`，强制 Path C，传入：
- evidence_level = light
- 验收步骤作为 case 列表（每个步骤映射为一个简单 case）
- 不要求 scenario.md 和 prep 文件（quick-run 豁免 readiness gate）

## Step 3: 后续动作

执行完成后，用 `AskUserQuestion`（multiSelect）：

| 选项 | 说明 |
|------|------|
| 沉淀为 Playwright 用例 (Recommended) | 成功时推荐；调用 test-automation-builder |
| 沉淀环境配置 | 将本次使用的 URL/账号/浏览器参数写入 shared/env/ |
| 转为完整设计模式 | 在已有 run 基础上补充 clarify-scope → scenario → prep |
| 重新执行 | 修改验收步骤后重跑 |
| 结束 | 完成 |

---

## 约束

1. **最多 1 次 AskUserQuestion**——只在输入不完整时补问，不做多轮澄清
2. 不需要 scenario.md、prep 文件——quick-run 豁免完整前置
3. evidence_level 固定 light——不问用户选择
4. 路径固定 C——不做路径决策
5. 失败时不自动进入 fix-script——只报告结果
6. 成功后主动推荐沉淀，但不强制

<IMPORTANT>
quick-run 的目标是"30 秒内开始浏览器操作"。任何阻止这个目标的确认环节都应该被跳过或自动推断。
</IMPORTANT>
