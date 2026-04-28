---
name: test-runner
description: 基于剧本、准备方案和自然语言/Markdown 验收步骤执行测试并生成质量报告。需要真实浏览器操作、Playwright 探索、截图、console/network 采集、失败归因或导出测试用例时优先使用本 skill。
allowed-tools: Read, Glob, Write, Skill, AskUserQuestion, Bash(npx playwright*), Bash(npx tsx*), Bash(mkdir*), mcp__plugin_playwright_playwright__browser_navigate, mcp__plugin_playwright_playwright__browser_snapshot, mcp__plugin_playwright_playwright__browser_click, mcp__plugin_playwright_playwright__browser_type, mcp__plugin_playwright_playwright__browser_fill_form, mcp__plugin_playwright_playwright__browser_select_option, mcp__plugin_playwright_playwright__browser_wait_for, mcp__plugin_playwright_playwright__browser_take_screenshot, mcp__plugin_playwright_playwright__browser_console_messages, mcp__plugin_playwright_playwright__browser_network_requests, mcp__plugin_playwright_playwright__browser_evaluate, mcp__plugin_playwright_playwright__browser_run_code, mcp__plugin_playwright_playwright__browser_close
---

# 测试执行器

通过准备度门禁、三路径策略和多层 oracle 验证执行测试，给出可信测试结论。

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
# e2e-script: npx playwright test .e2e-tests/shared/automation/{domain}/ts-{nnn}-*.spec.ts --reporter=json
```

#### 路径 B
调用 `test-automation-builder` 生成 → 执行 → 失败则降级到 C。

#### 路径 C
> **条件加载**：仅此时读取 `references/playwright-explore-guide.md`。

按 `evidence_level` 执行分级证据采集。逐 case 先用 `browser_snapshot` 探索页面，再执行 Step Mapping 中的验收步骤，采集截图、可访问性 snapshot、console、network、API 调用链和 evidence manifest，最后提炼接口知识与自动化导出建议。

Path C guardrails：
- 每个 case 最多一次同条件重试，仅用于页面未稳定、疑似 flaky、短暂网络抖动。
- 浏览器会话最多重建一次；重建后仍失败则归因，不继续循环。
- 权限错误、产品缺陷、oracle 缺失、环境阻塞、前置数据不可用不盲目重试。
- automation defect 才进入 `fix-script`；product defect / env issue / requirement-oracle unclear 只留证和报告。

### 阶段 3: 质量报告

> **条件加载**：此时读取 `references/report-template.md`。含 async/flaky 时才读 `references/async-and-flaky-guide.md`。

写报告前确保目录存在：`mkdir -p .e2e-tests/scenarios/{scenario}/runs/{run}/reports`

生成 `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/TS-{NNN}-run-{RRR}.md`。按 case 给出 PASS/FAIL/BLOCKED/SKIP。证据引用使用文件路径（如 `evidence/{case-id}/screenshots/then-result.png`），不用自由文本。报告必须包含 acceptance_step_ref、evidence_root、console/network artifacts、retry/fix history、export recommendation。

### 阶段 4: 沉淀判断与索引回写

**产物沉淀**（已完成，确认落盘）：
- 剧本已在 `.e2e-tests/scenarios/{scenario}/scenario.md` ✓
- 准备方案已在 `.e2e-tests/scenarios/{scenario}/runs/{run}/prep/` ✓
- 报告已在 `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/` ✓
- 证据已在 `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/` ✓

**脚本沉淀判断**（需条件）：路径成立 + 证据完整 + oracle 可判定 + 选择器稳定 + 准备可重复 + 登录/重置链路可复用 → 建议沉淀为 Playwright `.spec.ts` 或 API `.test.ts`。条件不满足时在 index.md 记录 `export_status=blocked` 和原因，不强制导出。

回写当前 run 的 `index.md`（报告路径、路径决策、case 结果、资产）。

### 阶段 4.5: 回写 quality-ledger、环境信息与认证脚本

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
- → 建议通过 `test-automation-builder` 沉淀为 `shared/automation/auth/login-{env}.test.ts`
- 脚本功能：传入账号密码 → 返回 token/cookie

### 阶段 5: 后续动作

`AskUserQuestion`（multiSelect）：补证据 / 重测 / 修改剧本 / 沉淀为 Playwright 用例 / 沉淀认证脚本 / 将 automation defect 交给 fix-script / 结束。

**主动推荐**：如果脚本沉淀条件满足，将"沉淀为 Playwright 用例"标注为 (Recommended)。如果认证脚本缺失，将"沉淀认证脚本"标注为 (Recommended)。如果失败归因为 automation defect，将"交给 fix-script"标注为 (Recommended)。

### 落盘检查

确认以下文件已写入：
- `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/TS-{NNN}-run-{RRR}.md`（报告）
- 当前 run 的 `index.md`（已更新）
- `.e2e-tests/shared/quality-ledger.md`（已更新或新建）

缺失则补写。

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

<IMPORTANT>
关键 oracle 缺失时，即使页面表现正常，也不能判 PASS。
</IMPORTANT>
