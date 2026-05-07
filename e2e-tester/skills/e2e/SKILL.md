---
name: e2e
description: 测试入口——用户提到任何形式的测试需求时默认触发此技能。TRIGGER when：用户说"测试"、"测一下"、"帮我测"、"验证"、"验收"、"试一下这个功能"、"test"、"e2e"、"回归"、"冒烟"、"跑一下"、"检查功能"、"看看有没有 bug"、"功能验证"、"浏览器测试"、"UI 测试"、"自动化测试"、"端到端"、"测试用例"、"测试脚本"、"失败定位"、"复现 bug"等。只要涉及功能验证、质量保障、测试执行、缺陷复现，均应先进入本入口装配任务再分流。SKIP：纯单元测试代码编写（jest/vitest 写法问题）、代码审查（不涉及测试执行）、性能压测（由 performance-benchmarker 承接）。
argument-hint: "<被测功能、发布范围、缺陷现象或回归目标>"
allowed-tools: Read, Write, Glob, Bash(mkdir*), AskUserQuestion, Skill
---

# QA 工作台入口

用户传入的参数：`$ARGUMENTS`

<IMPORTANT>
## 🚫 路径安全铁律（本文件最高优先级规则，任何操作前必须遵守）

**绝对禁止在 `.e2e-tests/` 以外创建以下任何目录或文件：**
- ❌ `task/`、`test/`、`temp/`、`output/`、`reports/` 目录
- ❌ 任何 `.png`、`.jpg`、`.jpeg` 截图文件
- ❌ 任何 `task.md`、`report.md`、`test-report.md` 文件
- ❌ 任何 `.spec.ts`、`.test.ts` 测试脚本文件

**所有产物唯一合法路径前缀：`.e2e-tests/`**

执行任何文件写入或 mkdir 前，必须验证路径以 `.e2e-tests/` 开头。若路径不以此开头——**停下来，修正路径后再执行**。

**`browser_take_screenshot` 强制规则：**
- 必须指定 `filename` 参数
- `filename` 必须以 `.e2e-tests/scenarios/` 开头
- 完整格式：`.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots/{name}.png`
- ❌ 禁止：`screenshot.png`、`page.png`、`test.png` 等纯文件名
- ❌ 禁止：`task/screenshot.png`、`test/result.png` 等非法路径

**违反此规则等同于执行失败。**
</IMPORTANT>

> **条件加载**：入口先读取 `references/intent-assembly-router.md` 做 workflow 分流。只有 workflow 确定后才按需加载对应 playbook。

**入口纪律**：自然语言测试请求、Markdown 验收步骤、浏览器真实操作验收、UI 自测、失败定位、成功后沉淀 Playwright 用例等，都先视为 `/e2e-tester:e2e` 入口任务。只有用户明确点名 `/e2e-tester:run-suite`、`/e2e-tester:fix-script`、`/e2e-tester:test-runner` 等子 skill，或明确要求”只跑现有回归/只修脚本”时，才直达子 skill。

---

## Step 0: 任务装配与 workflow 分流

### 显式快路由

明确意图时只做一次确认即可直达；否则仍先完成入口装配：
- 回归（"跑回归""run smoke""只跑已有脚本"）→ `run-suite`
- 修复（"fix ts-001""脚本跑不过""只修自动化脚本"）→ `fix-script`
- 影响分析（"这次改动影响什么"）→ `impact-analysis`
- 快速验收（用户贴了 URL + 验收步骤，且未要求完整设计/沉淀/发布验证）→ `quick-run`
- 泛化验收（"用浏览器测一下"、"这是验收清单"、"成功后沉淀 Playwright 用例"）→ 仍留在入口装配，不直达下游

### 自动推断（减少补问）

在发起 `AskUserQuestion` 前，先读取 `.e2e-tests/shared/knowledge-index.md`（如存在），利用已有知识加速推断：
- **环境**：knowledge-index「环境配置」表仅一行 → 直接使用，不问；多行 → 展示选择
- **scenario**：已有同名 scenario → 自动关联，创建新 run
- **已有脚本**：knowledge-index「自动化脚本」表命中 → 标记路径 A 候选，workflow 可推断为 `regression-batch`
- **URL + 步骤齐全 + 无显式设计需求**：自动推断 workflow = `express`，直达 `quick-run`
- **用户给了验收步骤但要求沉淀/发布验证**：推断 workflow = `design-lite` 或 `release-gate`
- **已知陷阱**：knowledge-index「已知陷阱」与当前场景匹配 → 自动注入 prep 注意事项

只有推断不了的字段才发起补问（合并为一次 `AskUserQuestion`）。

### 意图装配

非显式意图时，用 `AskUserQuestion` 按 `references/intent-assembly-router.md` 的装配补问流程收集信息。若用户贴了自然语言或 Markdown 验收步骤，保留原文，后续写入 `task.md` 的 Acceptance Source，并交给剧本阶段映射到 case/oracle/evidence。

### workflow 选择

| workflow | 使用场景 |
|----------|---------|
| `design-full` | 新功能、复杂验证、需完整策略对齐 |
| `design-lite` | 专项验证、目标明确，最小可信设计链 |
| `release-gate` | 发布前验证，优先 impact + run-suite + 定向补证据 |
| `regression-batch` | 直接批量跑脚本 |
| `impact-first` | 先影响分析再决定跑什么 |
| `repro-loop` | 缺陷复现，证据优先 |
| `script-maintenance` | 修脚本 / 沉淀脚本 |
| `express` | 快速验收，贴 URL + 步骤直达浏览器（由 quick-run 承接，但仍须满足落盘铁律）|

### design-lite 确认关卡

当路由结果为 `design-lite` 时，**必须在宣告前用 `AskUserQuestion` 确认**（见 `references/intent-assembly-router.md` 的确认规则）。用户可能虽然目标清晰，但仍希望沉淀环境数据和脚本——此时应切换为 `design-full`。

### workflow 执行入口

workflow 确定后，**必须先向用户宣告场景**再开始执行：

> 已识别本次为 **{workflow 中文名}** 场景。
> 目标：{一句话目标}
> 执行链路：{关键步骤概要}

- `regression-batch` → `run-suite`
- `impact-first` → `impact-analysis`
- `script-maintenance` → `fix-script` 或 `test-automation-builder`
- 浏览器验收 / Markdown 验收清单 / 成功后导出脚本 → 进入下方任务落盘流程，再由 `test-runner` Path C 和 `test-automation-builder` 承接
- 其他 → 进入下方任务落盘流程

---

## Step 1: 初始化与断点恢复

> 仅 `design-full` / `design-lite` / `release-gate` / `repro-loop` 需要此步。

1. 确定 **scenario-slug**（kebab-case，描述业务场景），`AskUserQuestion` 确认
2. 检查 `.e2e-tests/scenarios/{scenario-slug}/` 是否已存在：
   - **已存在** → 读取 `scenario.md`，在 `runs/` 下创建新 run
   - **不存在** → 创建完整的 scenario 文件夹结构
3. 生成 **run-slug**（kebab-case，描述本次执行目的），run 文件夹命名为 `{YYYY-MM-DD}-{run-slug}`
4. 创建目录（逐个 mkdir -p）：
   ```bash
   # 场景级（已存在时跳过）
   mkdir -p .e2e-tests/scenarios/{scenario-slug}/context
   mkdir -p .e2e-tests/scenarios/{scenario-slug}/runs
   # run 级
   mkdir -p .e2e-tests/scenarios/{scenario-slug}/runs/{date}-{run-slug}/prep
   mkdir -p .e2e-tests/scenarios/{scenario-slug}/runs/{date}-{run-slug}/reports
   mkdir -p .e2e-tests/scenarios/{scenario-slug}/runs/{date}-{run-slug}/evidence
   mkdir -p .e2e-tests/scenarios/{scenario-slug}/runs/{date}-{run-slug}/fixtures
   ```
5. 确保公共资产存在（不存在时用 Write 创建）：
   - `.e2e-tests/shared/datasets/`、`.e2e-tests/shared/mocks/`、`.e2e-tests/shared/helpers/`（mkdir -p）
   - `.e2e-tests/shared/automation/auth/`（mkdir -p）
   - `.e2e-tests/shared/registry/index.yaml` — 不存在时写入空结构：`version: 1\ndomains: {}`
   - `.e2e-tests/shared/asset-catalog.md` — 不存在时写入四区块空骨架（共享数据集/Mock/Helper/跨域脚本）
   - `.e2e-tests/shared/quality-ledger.md` — 不存在时按 `references/quality-ledger-template.md` 创建空结构
   - `.e2e-tests/shared/env/` 目录（mkdir -p）
6. 按 `references/index-template.md` 初始化 `.e2e-tests/scenarios/{scenario-slug}/runs/{date}-{run-slug}/index.md`（如不存在）
7. 以 index.md frontmatter + 实际产物推断接续点
8. 扫描共享资产 + 已有 scenario.md，`AskUserQuestion` 确认接续阶段

---

## Workflow 执行

确定 workflow 后，**条件加载**对应 playbook 执行：

| workflow | 加载文件 |
|----------|---------| 
| `design-full` / `design-lite` | `references/design-mode-steps.md` |
| `release-gate` | `references/release-readiness-playbook.md` |
| `repro-loop` | `references/bug-repro-playbook.md` |
| 专项验证 | `references/special-validation-catalog.md` |

---

## 上下文纪律

1. `index.md` 是唯一状态文件，断点恢复以产物为准
2. 每阶段从文件读上下文，不依赖对话记忆
3. 重型任务（scan-context、test-automation-builder）走 subagent
4. 逐阶段停顿等用户确认
5. quality-ledger 存在时加速，缺失不阻塞
6. workflow 可重判，切换时记入决策日志
7. 状态文件写入前检查行数，按 `references/file-size-control.md` 的阈值执行分片

<IMPORTANT>
默认心智是"先装配 QA 工作，再进入合适 workflow"，不是"所有事情都走新功能测试六阶段"。泛化测试消息不要绕过入口；入口负责把验收文本、环境参数、证据级别和导出意图稳定落盘。

## 产物落盘铁律（所有 workflow 共守）

1. NEVER 在 `.e2e-tests/` 以外的任何位置写入测试产物（报告、截图、脚本、配置）。禁止写入 `task/`、`test/`、`temp/`、`output/`、项目根目录。
2. 任何 workflow 进入执行前，必须先用 `mkdir -p` 创建完整的 `.e2e-tests/` 目录树。目录不存在则不执行。
3. 环境数据（URL/账号/API 端点/认证方式）一旦获取，立即写入 `.e2e-tests/shared/env/`，不允许只存在对话中。
4. 即使是 `express` / `quick-run` 路径，也必须在 `.e2e-tests/scenarios/{scenario}/` 下生成最小 scenario.md。
5. 脚本沉淀默认触发：Path C 成功后自动进入 `test-automation-builder`，用户可主动选择跳过。
6. 每个 skill 执行完成后用 `Glob` 校验产物是否落在 `.e2e-tests/` 下正确位置，缺失则补写。

## 路径自检清单（每次写文件前检查）

| 要写的东西 | ✅ 正确路径 | ❌ 错误路径（绝对禁止） |
|-----------|------------|---------------------|
| 任务卡 | `.e2e-tests/scenarios/{s}/runs/{r}/task.md` | `task/task.md`、`task.md` |
| 截图 | `.e2e-tests/scenarios/{s}/runs/{r}/evidence/{c}/screenshots/*.png` | `*.png`(根目录)、`test/*.png` |
| 报告 | `.e2e-tests/scenarios/{s}/runs/{r}/reports/*.md` | `test/report.md`、`report.md` |
| 测试脚本 | `.e2e-tests/shared/automation/{domain}/*.ts` | `test/*.ts`、`tests/*.ts` |
| 环境配置 | `.e2e-tests/shared/env/*.yaml` | `env.yaml`(根目录) |
| 知识索引 | `.e2e-tests/shared/knowledge-index.md` | `knowledge-index.md`(根目录) |
</IMPORTANT>
