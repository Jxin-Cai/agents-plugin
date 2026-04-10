---
name: e2e
description: E2E 测试完整流程——按顺序执行澄清、扫描、剧本生成、测试准备、测试执行、自动化沉淀
argument-hint: "<被测功能或应用描述>"
allowed-tools: Read, Write, Glob, Bash(mkdir*), AskUserQuestion, Skill
---

# E2E 测试完整流程

入口编排技能，串联六个阶段完成从测试任务定义到测试报告和自动化资产沉淀的完整 E2E 测试流程。

用户传入的参数：`$ARGUMENTS`

---

## 上下文管理纪律

> 本流程跨越 6 个阶段，上下文窗口是稀缺资源。必须遵守以下规则：

1. **阶段摘要必须落盘**：每个阶段结束时，将摘要写入 `.e2e-tests/{domain}/context/stage-{N}-summary.md`
2. **下阶段从文件读取**：每个阶段开始时，从文件读取前置阶段摘要，**不依赖对话记忆**
3. **参考文档条件加载**：模板和参考文档只在需要时读取，读完即用，不要在对话中复述其全文
4. **重型生成走 subagent**：代码扫描（scan-context）、脚本生成（test-automation-builder）必须通过 subagent 执行，避免大量中间内容污染主上下文

---

## Step 0: 初始化与断点恢复

1. 从 `$ARGUMENTS` 中提取测试目标，生成一个业务领域名（2-4 个词，kebab-case，如 `user-auth`、`order-flow`、`payment-checkout`）

2. 使用 `AskUserQuestion` 工具向用户确认业务领域名

3. **检查断点恢复**：检查 `.e2e-tests/{domain}/progress.yaml` 是否存在
   - 若存在，读取文件内容，使用 `AskUserQuestion` 向用户展示已完成的阶段和上次中断位置，询问：
     - 从上次中断的阶段继续
     - 从头开始（会清空已有产物）
   - 若选择继续，跳转到对应阶段

4. 创建工作目录 `.e2e-tests/{domain}/` 及子目录：context、scenarios、prep、automation、fixtures/mocks、reports、evidence

5. 初始化 `progress.yaml`：

```yaml
domain: {domain}
current_stage: 0
completed_stages: []
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DDTHH:mm:ss}
```

6. 如果 `.e2e-tests/registry.yaml` 不存在，创建初始文件：

```yaml
version: 3
updated: {ISO 8601}
scripts: []
```

7. 扫描 `.e2e-tests/` 报告已有领域、剧本数、自动化覆盖概况

---

## Step 1: 澄清测试任务

**阶段入口**：读取 `.e2e-tests/{domain}/progress.yaml` 确认当前阶段。

使用 Skill 工具调用 `clarify-scope` skill，传入 `$ARGUMENTS` 作为参数。等待该 skill 执行完毕。

**阶段完成标志：** 用户确认了测试任务定义（包含目标、风险等级、角色、边界、依赖策略、通过标准）。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-1-summary.md`：

```markdown
# Stage 1 摘要：测试任务定义

## 被测流程
- 名称: {流程名称}
- 风险等级: {High/Medium/Low}
- 测试目标: {验收/回归/发布前/问题复现}

## 成功判据
- {判据1}
- {判据2}

## 不可接受结果
- {结果1}
- {结果2}

## 关键依赖
| 服务 | 策略 | 备注 |
|------|------|------|
| {service} | {real/mock/fixture} | {说明} |

## 角色与权限
- {角色}: {权限说明}

## 测试边界（Out of Scope）
- {不测内容}
```

**更新 progress.yaml**：`current_stage: 2`，将 stage 1 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整测试任务 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 扫描项目上下文

**阶段入口**：读取 `.e2e-tests/{domain}/context/stage-1-summary.md` 获取测试任务定义。

使用 Skill 工具调用 `scan-context` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/context/` 下已有上下文摘要，且用户确认扫描结果充分。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-2-summary.md`：

```markdown
# Stage 2 摘要：项目上下文

## 上下文摘要文件
- {文件路径}

## 关键调用链
- {A → B → C}

## 异步链路与一致性窗口
- {链路}: 预计 {N}ms

## 可观察信号
- UI: {信号}
- API: {信号}
- Data: {信号}
- Side Effect: {信号}

## 可复用测试资产
- {资产路径和说明}
```

**更新 progress.yaml**：`current_stage: 3`，将 stage 2 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充扫描 / 跳过扫描直接进入剧本生成）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 构建测试剧本

**阶段入口**：读取以下文件获取前置上下文（不依赖对话记忆）：
- `.e2e-tests/{domain}/context/stage-1-summary.md`
- `.e2e-tests/{domain}/context/stage-2-summary.md`

使用 Skill 工具调用 `test-scenario-gen` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/scenarios/TS-{NNN}-*.md` 已生成，用户已审阅确认。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-3-summary.md`：

```markdown
# Stage 3 摘要：测试剧本

## 剧本文件列表
- {文件路径1}
- {文件路径2}

## 场景矩阵
| 场景 | 类型 | 风险 | 主要 Oracle | 剧本文件 |
|------|------|------|-------------|---------|
| {场景名} | {类型} | {风险} | {oracle} | {路径} |

## Mock 依赖
| 服务 | Mock 配置文件 |
|------|-------------|
| {service} | {路径} |
```

**更新 progress.yaml**：`current_stage: 4`，将 stage 3 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续准备测试 / 修改剧本 / 新增更多剧本 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 4: 准备测试环境与数据

**阶段入口**：读取以下文件获取前置上下文：
- `.e2e-tests/{domain}/context/stage-1-summary.md`（依赖策略）
- `.e2e-tests/{domain}/context/stage-3-summary.md`（剧本路径列表）

使用 Skill 工具调用 `test-prep` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/prep/TP-{NNN}-*.md` 已生成，准备度结论明确（READY / BLOCKED / PARTIAL）。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-4-summary.md`：

```markdown
# Stage 4 摘要：测试准备

## 准备方案列表
| 剧本 | 准备方案 | 准备度 |
|------|---------|--------|
| {TS-NNN} | {TP-NNN 路径} | {READY/PARTIAL/BLOCKED} |

## BLOCKED/PARTIAL 原因（如有）
- {原因}

## 关键 Mock/Fixture 文件
- {路径}
```

**更新 progress.yaml**：`current_stage: 5`，将 stage 4 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续执行测试 / 补充准备项 / 回到剧本修改 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 5: 执行测试

**阶段入口**：读取以下文件获取前置上下文：
- `.e2e-tests/{domain}/context/stage-3-summary.md`（剧本路径）
- `.e2e-tests/{domain}/context/stage-4-summary.md`（准备方案路径和准备度）

使用 Skill 工具调用 `test-runner` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md` 已生成。

**更新 progress.yaml**：`current_stage: 6`，将 stage 5 加入 `completed_stages`。

如果走路径 C 且全部通过，自动进入 Step 6。否则：

使用 `AskUserQuestion` 工具展示测试结果摘要，询问后续动作：
- 测试通过 → 选项：完成 / 沉淀为自动化脚本 / 执行更多剧本
- 测试失败 → 选项：查看失败分析 / 补充准备后重测 / 修改剧本后重测 / 结束流程

**⏸️ 等待用户选择后继续。**

---

## Step 6: 沉淀自动化脚本（条件触发）

**触发条件**：Step 5 走了路径 C 且全部通过（且 API 调用链摘要完整），或用户主动选择"沉淀为自动化脚本"。

**阶段入口**：读取以下文件：
- `.e2e-tests/{domain}/context/stage-3-summary.md`（剧本路径）
- `.e2e-tests/{domain}/context/stage-4-summary.md`（准备方案路径）
- 最近的测试报告文件（获取 API 调用链摘要）

使用 Skill 工具调用 `test-automation-builder` skill。等待该 skill 执行完毕。

**阶段完成标志：** 纯 API 脚本文件已生成（`.test.ts`），注册表已更新。

**更新 progress.yaml**：`current_stage: done`，将 stage 6 加入 `completed_stages`。

向用户展示：
- 生成的脚本文件绝对路径
- 脚本覆盖的 API 端点
- 注册表更新情况
- 测试报告的绝对路径
- 限制说明（哪些验证点仍需人工或 Playwright 探索确认）

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行，并同步更新 progress.yaml。
每个阶段开始时必须从文件读取前置摘要，不要依赖对话中的历史信息——对话历史可能不完整。
</IMPORTANT>
