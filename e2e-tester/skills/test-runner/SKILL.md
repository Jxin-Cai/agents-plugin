---
name: test-runner
description: 基于剧本、准备方案和自然语言/Markdown 验收步骤执行测试并生成质量报告。需要真实浏览器操作、Playwright 探索、截图、console/network 采集、失败归因或导出测试用例时优先使用本 skill。
allowed-tools: Read, Glob, Write, Skill, AskUserQuestion, Bash(npx playwright*), Bash(npx tsx*), Bash(mkdir*), mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_snapshot, mcp__plugin_playwright_playwright__browser_click, mcp__plugin_playwright_playwright__browser_type, mcp__plugin_playwright_playwright__browser_fill_form, mcp__plugin_playwright_playwright__browser_select_option, mcp__plugin_playwright_playwright__browser_wait_for, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_console_messages, mcp__plugin_playwright_playwright__browser_network_requests, mcp__plugin_playwright_playwright__browser_evaluate, mcp__plugin_playwright_playwright__browser_run_code, mcp__plugin_playwright_playwright__browser_close
---

# 测试执行器

通过准备度门禁、三路径策略和多层 oracle 验证执行测试，给出可信测试结论。

<IMPORTANT>
## 🚫 路径安全铁律（最高优先级——任何操作前必读）

**所有文件写入、mkdir、browser_take_screenshot 的目标路径必须以 `.e2e-tests/` 开头。没有例外。**

### browser_take_screenshot 强制规则

每次调用 `browser_take_screenshot` 前，按此模板构造 filename：

```
filename: ".e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots/{name}.png"
```

**禁止写法示例（违反即执行失败）：**
- ❌ `filename: "screenshot.png"` — 会写到项目根目录
- ❌ `filename: "test/result.png"` — 会创建 test/ 目录
- ❌ `filename: "task/evidence.png"` — 会创建 task/ 目录
- ❌ 不传 filename 参数 — Playwright MCP 默认写到 CWD

**正确写法示例：**
- ✅ `filename: ".e2e-tests/scenarios/login-flow/runs/2026-05-07-quick-1430/evidence/case-01/screenshots/given-verified.png"`
- ✅ `filename: ".e2e-tests/scenarios/login-flow/runs/2026-05-07-quick-1430/evidence/case-01/screenshots/then-result.png"`

### 文件写入路径对照

| 产物 | ✅ 唯一合法路径 | ❌ 绝对禁止 |
|------|--------------|-----------|
| 截图 | `.e2e-tests/scenarios/{s}/runs/{r}/evidence/{c}/screenshots/` | 根目录、`test/`、`task/` |
| 报告 | `.e2e-tests/scenarios/{s}/runs/{r}/reports/` | 根目录、`test/` |
| 环境配置 | `.e2e-tests/shared/env/` | 根目录 |
| 测试脚本 | `.e2e-tests/shared/automation/` | `test/`、`tests/` |
| console 日志 | `.e2e-tests/scenarios/{s}/runs/{r}/evidence/{c}/console/` | 根目录 |
| network 数据 | `.e2e-tests/scenarios/{s}/runs/{r}/evidence/{c}/network/` | 根目录 |
| API 响应 | `.e2e-tests/scenarios/{s}/runs/{r}/evidence/{c}/api/` | 根目录 |

### 执行前三步检查

1. **拼路径** — 用变量展开完整路径，确认以 `.e2e-tests/` 开头
2. **建目录** — `mkdir -p {完整路径的父目录}`
3. **再操作** — 确认路径正确后再 Write/screenshot/保存
</IMPORTANT>

## 产物落盘铁律

> 以下规则不可违反，无论哪个路径、哪个 workflow。

1. **所有截图、报告、证据只能写入 `.e2e-tests/` 目录内**。NEVER 写入 `task/`、`test/`、`temp/`、项目根目录等其他位置。
2. **截图必须保存到 `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots/`**。使用 `browser_take_screenshot` 时，必须指定 `filename` 参数且路径以 `.e2e-tests/scenarios/` 开头。
3. **执行前必须 mkdir -p 创建证据目录**。每个 case 开始执行前：`mkdir -p .e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots`
4. **环境信息必须立即沉淀**。执行过程中获取到的 URL、API 端点、认证信息、浏览器配置，必须写入 `.e2e-tests/shared/env/{target_env}.yaml`，不允许只记在对话中。
5. **npx playwright test 输出目录**。运行 Playwright CLI 时必须指定 `--output=.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/playwright-results`，防止默认 `test-results/` 目录泄漏到根目录。

## 路径变量

以下用 `{scenario}` 代替 `{scenario-slug}`，`{run}` 代替 `{YYYY-MM-DD}-{run-slug}`。

## 流程

### 阶段 0: 读取输入与 readiness gate

读取当前 run 的 `task.md`（含 Acceptance Source 原文和 export_intent）、`index.md`、`.e2e-tests/scenarios/{scenario}/scenario.md`（剧本与 Step Mapping）、`.e2e-tests/scenarios/{scenario}/runs/{run}/prep/` 下的方案、已有报告、`.e2e-tests/shared/quality-ledger.md`（只提取与当前 domain 相关的时序基线、失败模式、环境陷阱条目）、`.e2e-tests/shared/env/{target_env}.yaml`（如存在，含 browser/start_urls/preflight/deploy/stability）。
- readiness = BLOCKED → 停止执行
- real 依赖不可用且无降级 → BLOCKED

**证据级别确认**：从当前 run 的 `index.md` frontmatter 读取 `evidence_level`。若缺失，用 `AskUserQuestion` 引导选择：

| 选项 | 说明 | 默认推荐场景 |
|------|------|-------------|
| light | 关键截图 + 关键 API 出入参对 | design-lite、快速验证 |
| standard | 每步截图 + 完整 API 链 + 错误日志 | 一般场景（推荐） |
| strict | 密集截图序列 + 可访问性快照 + 全量日志 | release-gate、合规审计 |

选择后回写 index.md frontmatter。

### 阶段 1: 资产检索与路径决策

查询 `.e2e-tests/shared/registry/`、`.e2e-tests/shared/asset-catalog.md`、task 文件。匹配已有脚本（精确 → 模糊 → 辅助）。

| 路径 | 条件 |
|------|------|
| A 自动化 | 已有脚本匹配 |
| B 生成后执行 | oracle 可机械验证 + prep 完整 + 页面稳定 |
| C Playwright 探索 | 其他情况（不确定时默认 C）；用户给自然语言/Markdown 验收步骤、需要真实浏览器操作、需要 console/network 证据或成功后导出 `.spec.ts` 时优先 C |

### 阶段 2: 执行

#### 路径 A
```bash
# api-script: npx tsx .e2e-tests/shared/automation/{domain}/ts-{nnn}-*.test.ts
# e2e-script: npx playwright test .e2e-tests/shared/automation/{domain}/ts-{nnn}-*.spec.ts --reporter=json --output=.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/playwright-results
```

#### 路径 B
调用 `test-automation-builder` 生成 → 执行 → 失败则降级到 C。

#### 路径 C
> **条件加载**：仅此时读取 `references/playwright-explore-guide.md`（索引），再按阶段加载子文件：
> - 开始前：`references/explore-setup.md`（证据级别 + 浏览器启动 + 第三方脚本屏蔽）
> - 逐 case 执行时：`references/explore-evidence-rules.md`（截图/网络/console 分级采集）
> - 失败或完成时：`references/explore-failure-and-output.md`（归因 + 输出格式）

按 `evidence_level` 执行分级证据采集。逐 case 先用 `browser_snapshot` 探索页面，再执行 Step Mapping 中的验收步骤，采集截图、可访问性 snapshot、console、network、API 调用链和 evidence manifest，最后提炼接口知识与自动化导出建议。

Path C guardrails：
- 每个 case 最多一次同条件重试，仅用于页面未稳定、疑似 flaky、短暂网络抖动。
- 浏览器会话最多重建一次；重建后仍失败则归因，不继续循环。
- 权限错误、产品缺陷、oracle 缺失、环境阻塞、前置数据不可用不盲目重试。
- automation defect 才进入 `fix-script`；product defect / env issue / requirement-oracle unclear 只留证和报告。

### 阶段 3: 质量报告

> **条件加载**：此时先读 `references/report-rules.md`（骨架与规则），生成时再读 `references/report-template.md`（完整模板）。含 async/flaky 时才读 `references/async-and-flaky-guide.md`。

写报告前确保目录存在：`mkdir -p .e2e-tests/scenarios/{scenario}/runs/{run}/reports`

生成 `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/TS-{NNN}-run-{RRR}.md`。按 case 给出 PASS/FAIL/BLOCKED/SKIP。证据引用使用文件路径（如 `evidence/{case-id}/screenshots/then-result.png`），不用自由文本。报告必须包含 acceptance_step_ref、evidence_root、console/network artifacts、retry/fix history、export recommendation。

### 阶段 4: 沉淀判断与索引回写

**产物沉淀**（已完成，确认落盘）：
- 剧本已在 `.e2e-tests/scenarios/{scenario}/scenario.md` ✓
- 准备方案已在 `.e2e-tests/scenarios/{scenario}/runs/{run}/prep/` ✓
- 报告已在 `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/` ✓
- 证据已在 `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/` ✓

**脚本沉淀判断**（默认触发）：路径 C 执行成功时，默认调用 `test-automation-builder` 沉淀为 Playwright `.spec.ts` 或 API `.test.ts`。仅当以下条件**全部不满足**时阻止沉淀：oracle 不可判定、选择器不稳定、准备不可重复、登录/重置链路不可复用。条件不满足时在 index.md 记录 `export_status=blocked` 和具体原因。

回写当前 run 的 `index.md`（报告路径、路径决策、case 结果、资产）。

### 阶段 4.5: 回写 quality-ledger、环境信息、认证脚本与知识索引

写入 `.e2e-tests/shared/quality-ledger.md`（不存在时按 `skills/e2e/references/quality-ledger-template.md` 创建空结构后再写入）。

内容：失败模式、时序基线、环境陷阱、依赖稳定性、flaky 治理。

若执行过程中发现以下新增环境信息，也应回写 `.e2e-tests/shared/env/{target_env}.yaml`：
- 新识别的认证方式 / token 使用方式
- 新确认的关键 API 端点
- 需要屏蔽的第三方脚本模式
- 环境陷阱 / known_traps
- 新确认的 start_urls / browser profile / preflight checks / stability windows / deploy_scripts

**认证脚本沉淀检查**：如果路径 C 执行了登录操作：
- 捕获到登录 API 调用链（认证端点 + token 返回）
- 且 `shared/automation/auth/` 下没有对应环境的认证脚本
- → 建议通过 `test-automation-builder` 沉淀为 `shared/automation/auth/login-{env}.test.ts`（默认执行，不等用户选择）
- 脚本功能：传入账号密码 → 返回 token/cookie

**知识索引回写**：更新 `.e2e-tests/shared/knowledge-index.md`：
- 「活跃剧本」表：更新当前 scenario 的最后 run、状态、case 数
- 「已知陷阱」表：如本次发现新失败模式/环境陷阱，追加（保持 Top 5 Active）
- 「环境配置」表：如本次使用了新环境配置，确保已登记

### 阶段 5: 后续动作

**脚本沉淀自动执行**：如果 Path C 成功且脚本沉淀条件满足（阶段 4 判定），直接调用 `test-automation-builder` 执行沉淀，不等用户选择。沉淀完成后再提供后续选项。

`AskUserQuestion`（multiSelect）：补证据 / 重测 / 修改剧本 / 沉淀认证脚本 / 将 automation defect 交给 fix-script / 结束。

**主动推荐**：如果认证脚本缺失，将"沉淀认证脚本"标注为 (Recommended)。如果失败归因为 automation defect，将"交给 fix-script"标注为 (Recommended)。

### 落盘检查

用 `Glob` 逐项确认以下文件已写入 `.e2e-tests/` 下正确位置：
- `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/TS-{NNN}-run-{RRR}.md`（报告）
- `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/`（至少有一个 case 子目录含截图）
- `.e2e-tests/scenarios/{scenario}/scenario.md`（剧本，即使是 quick-run 也需要最小版本）
- `.e2e-tests/shared/env/{target_env}.yaml`（环境配置）
- `.e2e-tests/shared/knowledge-index.md`（已更新）
- `.e2e-tests/shared/quality-ledger.md`（已更新或新建）
- 当前 run 的 `index.md`（已更新）

**任何一项缺失则立即补写，不能跳过。**
**如果发现报告、截图等产物错误地写到了 `.e2e-tests/` 以外的位置，必须将其移动到正确位置。**

## 约束

1. 无准备不执行
2. 无关键证据不判 PASS
3. 失败必须归类
4. 不确定时优先路径 C
5. 优先复用已有资产
6. 按 case 逐个判定
7. Path C 必须真实操作浏览器，不能只靠静态推断
8. console/network 错误必须落 artifact 并在报告中引用
9. 重试必须受 guardrails 限制并记录次数与原因
10. NEVER 在 `.e2e-tests/` 以外写入任何测试产物（报告、截图、脚本、日志）
11. 环境数据一旦获取必须立即写入 `.e2e-tests/shared/env/`
12. Path C 成功后默认沉淀脚本，不等用户选择
13. `browser_take_screenshot` 的 `filename` 参数必须以 `.e2e-tests/scenarios/` 开头——纯文件名或不含此前缀的路径等同于执行失败
14. `npx playwright test` 必须带 `--output=.e2e-tests/...` 参数，防止 `test-results/` 泄漏

<IMPORTANT>
关键 oracle 缺失时，即使页面表现正常，也不能判 PASS。
测试产物 NEVER 写到 `.e2e-tests/` 以外——这是不可商量的铁律。
每次调用 browser_take_screenshot 前，先心算路径是否以 `.e2e-tests/scenarios/` 开头。不是？停下来修正。
</IMPORTANT>
