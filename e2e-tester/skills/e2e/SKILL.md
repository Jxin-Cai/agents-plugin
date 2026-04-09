---
name: e2e
description: E2E 测试完整流程——按顺序执行澄清、扫描、剧本生成、测试准备、测试执行、自动化沉淀
argument-hint: "<被测功能或应用描述>"
allowed-tools: Read, Glob, Bash(mkdir*), AskUserQuestion
---

# E2E 测试完整流程

入口编排技能，串联六个阶段完成从测试任务定义到测试报告和自动化资产沉淀的完整 E2E 测试流程。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 初始化

1. 从 `$ARGUMENTS` 中提取测试目标，生成一个业务领域名（2-4 个词，kebab-case，如 `user-auth`、`order-flow`、`payment-checkout`）

2. 使用 `AskUserQuestion` 工具向用户确认业务领域名

3. 创建工作目录 `.e2e-tests/{domain}/` 及子目录：context、scenarios、prep、automation、fixtures/mocks、reports、evidence

4. 扫描 `.e2e-tests/` 报告已有领域、剧本数、自动化覆盖概况

---

## Step 1: 澄清测试任务

调用 `/clarify-scope $ARGUMENTS`

**阶段完成标志：** 用户确认了测试任务定义（包含目标、风险等级、角色、边界、依赖策略、通过标准）。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 调整测试任务 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 扫描项目上下文

调用 `/scan-context`

**阶段完成标志：** `.e2e-tests/{domain}/context/` 下已有上下文摘要，且用户确认扫描结果充分。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续下一阶段 / 补充扫描 / 跳过扫描直接进入剧本生成）。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 构建测试剧本

调用 `/test-scenario-gen`

**阶段完成标志：** `.e2e-tests/{domain}/scenarios/TS-{NNN}-*.md` 已生成，用户已审阅确认。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续准备测试 / 修改剧本 / 新增更多剧本 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 4: 准备测试环境与数据

调用 `/test-prep`

**阶段完成标志：** `.e2e-tests/{domain}/prep/TP-{NNN}-*.md` 已生成，准备度结论明确（READY / BLOCKED / PARTIAL）。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段（选项：继续执行测试 / 补充准备项 / 回到剧本修改 / 结束流程）。

**⏸️ 等待用户选择后继续。**

---

## Step 5: 执行测试

调用 `/test-runner`

**阶段完成标志：** `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md` 已生成。

如果走路径 C 且全部通过，自动进入 Step 6。否则：

使用 `AskUserQuestion` 工具展示测试结果摘要，询问后续动作：
- 测试通过 → 选项：完成 / 沉淀为自动化脚本 / 执行更多剧本
- 测试失败 → 选项：查看失败分析 / 补充准备后重测 / 修改剧本后重测 / 结束流程

**⏸️ 等待用户选择后继续。**

---

## Step 6: 沉淀自动化脚本（条件触发）

**触发条件**：Step 5 走了路径 C 且全部通过，或用户主动选择”沉淀为自动化脚本”。

调用 `/test-automation-builder`

**阶段完成标志：** 脚本文件已生成，注册表已更新。

向用户展示：
- 生成的脚本文件绝对路径
- 注册表更新情况
- 测试报告的绝对路径

---

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行。
</IMPORTANT>
