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
  - export_intent = `auto`（成功后自动沉淀脚本，用户可事后跳过）

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
   mkdir -p .e2e-tests/shared/env
   ```
4. 写入精简 `task.md`（只含 URL、验收步骤原文、evidence_level=light）
5. 写入精简 `index.md`（frontmatter 只填必要字段，正文留空）
6. **生成最小 scenario.md**（必须，不可跳过）：写入 `.e2e-tests/scenarios/{scenario}/scenario.md`，至少包含：
   ```markdown
   ---
   goal: {从验收步骤推断的一句话目标}
   workflow: express
   created: {YYYY-MM-DD}
   ---
   # {scenario-slug}
   ## Cases
   {每个验收步骤映射为一个 case，包含 case-id、步骤描述、oracle 类型}
   ```
7. **环境配置必须沉淀**（不可跳过）：
   - 检查 `.e2e-tests/shared/env/` 是否有匹配的环境配置
   - 有 → 读取并使用
   - 无 → **立即创建**环境配置 `.e2e-tests/shared/env/{env-name}.yaml`（包含 base_url + name + 发现的所有环境信息）；同时检查 session-start 发现的项目环境线索（package.json proxy、.env BASE_URL、playwright.config baseURL），自动补充 api_base_url 和 blocked_scripts
8. 更新 `.e2e-tests/shared/knowledge-index.md`「环境配置」和「活跃剧本」表

## Step 2: 直达 test-runner

调用 `test-runner`，强制 Path C，传入：
- evidence_level = light
- 验收步骤作为 case 列表（每个步骤映射为一个简单 case）
- scenario.md 已在 Step 1 生成（最小版本），test-runner 可读取
- quick-run 豁免 prep 文件，但不豁免 scenario.md 和环境配置

## Step 3: 自动沉淀与后续动作

**脚本自动沉淀**：Path C 成功后，直接调用 `test-automation-builder` 将验收步骤沉淀为 `.spec.ts`。用户在下一步可选择跳过（但默认执行，不问确认）。

沉淀完成后，用 `AskUserQuestion`（multiSelect）：

| 选项 | 说明 |
|------|------|
| 转为完整设计模式 | 在已有 run 基础上补充 clarify-scope → scenario → prep |
| 重新执行 | 修改验收步骤后重跑 |
| 结束 | 完成 |

---

## 落盘检查

用 `Glob` 逐项确认以下文件已写入 `.e2e-tests/` 下正确位置：
- `.e2e-tests/scenarios/{scenario}/scenario.md`（最小剧本）
- `.e2e-tests/scenarios/{scenario}/runs/{date}-{run}/task.md`（任务卡）
- `.e2e-tests/scenarios/{scenario}/runs/{date}-{run}/index.md`（状态文件）
- `.e2e-tests/scenarios/{scenario}/runs/{date}-{run}/reports/`（测试报告）
- `.e2e-tests/scenarios/{scenario}/runs/{date}-{run}/evidence/`（截图等证据）
- `.e2e-tests/shared/env/{env-name}.yaml`（环境配置）
- `.e2e-tests/shared/knowledge-index.md`（已更新）

**任何一项缺失则立即补写。NEVER 在 `.e2e-tests/` 以外的位置写入任何测试产物。**

---

## 约束

1. **最多 1 次 AskUserQuestion**——只在输入不完整时补问，不做多轮澄清
2. **必须生成最小 scenario.md**——quick-run 豁免的是完整 BDD 设计流程，不是剧本文件本身
3. **环境配置必须沉淀**——不是可选项，是强制要求
4. evidence_level 固定 light——不问用户选择
5. 路径固定 C——不做路径决策
6. 失败时不自动进入 fix-script——只报告结果
7. **成功后自动沉淀脚本**——不问用户确认，用户可事后选择跳过
8. NEVER 在 `.e2e-tests/` 以外写入任何测试产物

<IMPORTANT>
quick-run 的目标是"30 秒内开始浏览器操作"。任何阻止这个目标的确认环节都应该被跳过或自动推断。
但"快"不等于"不留痕"——环境数据、最小剧本、报告和截图必须落盘到 `.e2e-tests/`，成功后脚本必须自动沉淀。quick-run 跳过的是"设计仪式"，不是"产物沉淀"。
</IMPORTANT>
