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

## 上下文管理与资产纪律

> 本流程跨越 6 个阶段。主线不是对话历史，而是当前任务文件和可复用资产目录。

1. **当前任务必须落盘**：`task/task.md` 是本次测试的一级输入；`task/index.md` 是本次任务的总索引
2. **阶段摘要继续保留**：每个阶段完成后，将摘要写入 `.e2e-tests/{domain}/context/stage-{N}-summary.md`
3. **共享资产优先**：进入澄清、准备、执行、沉淀前，先检索 `.e2e-tests/_shared/**`、`asset-catalog.md`、`registry.yaml`
4. **下阶段从文件读取**：每个阶段开始时，从 `task/task.md`、`task/index.md` 和前置摘要读取上下文，**不依赖对话记忆**
5. **重型生成走 subagent**：代码扫描（scan-context）、脚本生成（test-automation-builder）必须通过 subagent 执行，避免污染主上下文
6. **逐阶段停顿**：每个阶段结束后必须等待用户确认，不自动跳步
7. **选择题默认允许自定义答案**：使用 `AskUserQuestion` 时，默认允许用户通过内置 Other 提供自定义输入；当多个动作可同时成立时，应使用 `multiSelect: true`

---

## Step 0: 初始化、进度判断与断点恢复

1. 从 `$ARGUMENTS` 中提取测试目标，生成一个业务领域名（2-4 个词，kebab-case，如 `user-auth`、`order-flow`、`payment-checkout`）
2. 使用 `AskUserQuestion` 工具向用户确认业务领域名；若用户觉得命名不合适，应允许其直接自定义输入
3. 创建或确认工作目录 `.e2e-tests/{domain}/` 及子目录：`task`、`context`、`scenarios`、`prep`、`automation`、`fixtures`、`reports`、`evidence`
4. 确保共享目录存在：`.e2e-tests/_shared/datasets`、`.e2e-tests/_shared/mocks`、`.e2e-tests/_shared/helpers`
5. 如果 `.e2e-tests/registry.yaml` 不存在，创建初始文件：

```yaml
version: 4
updated: {ISO 8601}
scripts: []
```

6. 如果 `.e2e-tests/asset-catalog.md` 不存在，创建初始文件，至少包含：共享数据集、共享 mock、共享 helper、可复用脚本四个区块
7. 如果 `.e2e-tests/{domain}/task/index.md` 不存在，初始化该文件，至少包含：任务文件、阶段产物、候选可复用资产、最终沉淀资产四个区块
8. **整体进度判断**：不要只信 `progress.yaml`。同时检查以下信号：
   - `task/task.md` 是否存在
   - `context/stage-1-summary.md` ~ `stage-4-summary.md` 是否存在
   - `scenarios/TS-*.md` 是否存在
   - `prep/TP-*.md` 是否存在
   - `reports/**/TS-*-run-*.md` 是否存在
   - `automation/*.test.ts` 是否存在
   - `task/index.md` 中是否已记录这些产物
9. **推断当前可接续阶段**：
   - 若无 `task/task.md` → 从 Step 1 开始
   - 若有 `task/task.md` 但无上下文摘要 / 无用户确认痕迹 → 从 Step 1 重新确认或补齐
   - 若有 task + stage-2 摘要但无剧本 → 从 Step 3 开始
   - 若有剧本但无 prep → 从 Step 4 开始
   - 若有 prep 但无报告 → 从 Step 5 开始
   - 若已有报告且结论建议沉淀、但无脚本 → 从 Step 6 开始
   - 若脚本和索引都已齐备 → 向用户说明该任务已完成，可选择重跑、补测或新建任务
10. **检查断点恢复**：若 `.e2e-tests/{domain}/progress.yaml` 存在，读取其中内容，但仅将其视为辅助信息；以实际文件产物和 `task/index.md` 为准
11. 向用户展示“当前已产出的文档 / 资产”和“建议接续阶段”，并使用 `AskUserQuestion` 询问：
   - 从建议阶段继续
   - 回到更早阶段重做
   - 基于现有文档直接补充某个阶段
   - 从头开始创建新一轮任务（涉及重建产物时需再次确认）
   这里通常建议 `multiSelect: false`；但若用户想同时“补充扫描 + 修改剧本”，应允许使用 `multiSelect: true` 收集组合动作
12. 初始化或更新 `progress.yaml`：

```yaml
domain: {domain}
current_stage: {推断或用户选择后的阶段}
completed_stages: [{已确认完成的阶段}]
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DDTHH:mm:ss}
resume_basis:
  - task/index.md
  - stage summaries
  - scenario/prep/report/script artifacts
```

13. 扫描 `.e2e-tests/_shared/**`、`asset-catalog.md`、`registry.yaml`，向用户简要报告已有的可复用数据集、mock、helper、自动化脚本

---

## Step 1: 澄清测试任务

**阶段入口**：读取 `.e2e-tests/{domain}/progress.yaml` 与 `.e2e-tests/{domain}/task/index.md`；若已存在 `task/task.md`，先读取并判断是补充、重审还是重写。

使用 Skill 工具调用 `clarify-scope` skill，传入 `$ARGUMENTS` 作为参数。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/task/task.md` 已生成或已基于现有内容更新，且用户确认该测试任务文件可作为后续阶段的一级输入。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-1-summary.md`：

```markdown
# Stage 1 摘要：测试任务定义

## 任务文件
- `task/task.md`

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

## 候选可复用资产
- {共享数据集 / mock / helper / 脚本}

## 测试边界（Out of Scope）
- {不测内容}
```

**更新 `task/index.md`**：同步记录 `task/task.md`、候选可复用资产、当前仍缺失的信息。

**更新 progress.yaml**：`current_stage: 2`，将 stage 1 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段；如果用户可能想同时做多件事（例如“先补充一个依赖，再进入下一阶段”），应使用 `multiSelect: true`。

**⏸️ 等待用户选择后继续。**

---

## Step 2: 扫描项目上下文

**阶段入口**：读取以下文件获取前置上下文：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`
- `.e2e-tests/{domain}/context/stage-1-summary.md`

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

## 已识别可复用资产
- {资产路径和说明}
```

**更新 `task/index.md`**：同步记录上下文摘要文件、关键调用链、已识别可复用资产。

**更新 progress.yaml**：`current_stage: 3`，将 stage 2 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段；当“补充扫描 + 保留当前结果”可能同时成立时，使用 `multiSelect: true`。

**⏸️ 等待用户选择后继续。**

---

## Step 3: 构建测试剧本

**阶段入口**：读取以下文件获取前置上下文（不依赖对话记忆）：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`
- `.e2e-tests/{domain}/context/stage-1-summary.md`
- `.e2e-tests/{domain}/context/stage-2-summary.md`

使用 Skill 工具调用 `test-scenario-gen` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/scenarios/TS-{NNN}-*.md` 已生成；每个文件对应一个业务场景，且每个剧本内含多个 case；用户已审阅确认。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-3-summary.md`：

```markdown
# Stage 3 摘要：测试剧本

## 剧本文件列表
- {文件路径1}
- {文件路径2}

## 剧本列表
| 剧本 | 业务场景 | case 数 | 风险 | 主要 Oracle | 复用资产 |
|------|----------|---------|------|-------------|---------|
| {TS-NNN} | {场景名} | {N} | {风险} | {oracle} | {资产} |
```

**更新 `task/index.md`**：同步记录剧本文件列表、case 数量、被引用的数据集/mock/历史脚本。

**更新 progress.yaml**：`current_stage: 4`，将 stage 3 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段；当用户可能同时“增加一个 case + 调整优先级”时，使用 `multiSelect: true`。

**⏸️ 等待用户选择后继续。**

---

## Step 4: 准备测试环境与数据

**阶段入口**：读取以下文件获取前置上下文：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`
- `.e2e-tests/{domain}/context/stage-3-summary.md`

使用 Skill 工具调用 `test-prep` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/prep/TP-{NNN}-*.md` 已生成，准备度结论明确（READY / BLOCKED / PARTIAL），并已说明复用了哪些共享资产、沉淀了哪些新资产。

**阶段摘要落盘：** 将以下信息写入 `.e2e-tests/{domain}/context/stage-4-summary.md`：

```markdown
# Stage 4 摘要：测试准备

## 准备方案列表
| 剧本 | 准备方案 | 准备度 |
|------|---------|--------|
| {TS-NNN} | {TP-NNN 路径} | {READY/PARTIAL/BLOCKED} |

## 资产决策
- 复用资产: {路径和说明}
- 新增共享资产: {路径和说明}
- 任务专用资产: {路径和说明}

## BLOCKED/PARTIAL 原因（如有）
- {原因}
```

**更新 `task/index.md`**：同步记录准备方案、资产决策和 readiness 结论。

**更新 progress.yaml**：`current_stage: 5`，将 stage 4 加入 `completed_stages`。

使用 `AskUserQuestion` 工具询问用户是否进入下一阶段；当“补充准备项 + 回到剧本修改”可能同时成立时，使用 `multiSelect: true`。

**⏸️ 等待用户选择后继续。**

---

## Step 5: 执行测试

**阶段入口**：读取以下文件获取前置上下文：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`
- `.e2e-tests/{domain}/context/stage-3-summary.md`
- `.e2e-tests/{domain}/context/stage-4-summary.md`

使用 Skill 工具调用 `test-runner` skill。等待该 skill 执行完毕。

**阶段完成标志：** `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md` 已生成，且报告按 case 逐个给出验证结论。

**更新 `task/index.md`**：同步记录报告路径、执行方式、case 结果和新增证据。

**更新 progress.yaml**：`current_stage: 6`，将 stage 5 加入 `completed_stages`。

如果走路径 B/C 且结论适合沉淀，进入 Step 6。否则：

使用 `AskUserQuestion` 工具展示测试结果摘要，询问后续动作；当用户可能想“查看失败分析 + 补充准备后重测”时，使用 `multiSelect: true`。

**⏸️ 等待用户选择后继续。**

---

## Step 6: 沉淀自动化脚本（条件触发）

**触发条件**：Step 5 产出足够证据支持自动化沉淀，或用户主动选择“沉淀为自动化脚本”。

**阶段入口**：读取以下文件：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`
- `.e2e-tests/{domain}/context/stage-3-summary.md`
- `.e2e-tests/{domain}/context/stage-4-summary.md`
- 最近的测试报告文件

使用 Skill 工具调用 `test-automation-builder` skill。等待该 skill 执行完毕。

**阶段完成标志：** 纯 API 脚本文件已生成（`.test.ts`），`registry.yaml` 与 `asset-catalog.md` 已更新，脚本依赖的数据集/mock/helper 已登记。

**更新 `task/index.md`**：同步记录脚本路径、覆盖范围、依赖资产和沉淀结论。

**更新 progress.yaml**：`current_stage: done`，将 stage 6 加入 `completed_stages`。

向用户展示：
- 生成的脚本文件绝对路径
- 脚本覆盖的业务场景与 case
- 复用/新增的数据集、mock、helper
- 注册表与资产目录更新情况
- 测试报告的绝对路径
- 限制说明（哪些验证点仍需人工或 Playwright 探索确认）

---

## 接续规则

1. **接续基于产物，不基于记忆**：恢复工作时，优先读取 `task/task.md`、`task/index.md`、阶段摘要、剧本、准备方案、报告、脚本
2. **进度由实际文件推断**：`progress.yaml` 只能辅助，若与实际产物冲突，以实际产物为准
3. **接续前先做完整性检查**：若某阶段的主文件存在但缺少必要字段，应停在该阶段补齐，而不是跳到后面
4. **允许基于已有文档重开某阶段**：例如已存在剧本，但要回到澄清或扫描补充上下文；此时保留已有文档并在索引中标注“重审/重做”
5. **重新开始不等于删除历史**：除非用户明确要求清空，否则默认在现有任务文档上续写、修订或追加，不擅自删除旧产物

<IMPORTANT>
每个阶段完成后必须等待用户确认再进入下一阶段。不要跳过任何阶段。
如果用户中途要求调整（回到上一步、跳过某步），按用户指令执行，并同步更新 `progress.yaml` 与 `task/index.md`。
每个阶段开始时必须从文件读取前置摘要，不要依赖对话中的历史信息——对话历史可能不完整。
没有 `task/task.md`，不得进入剧本、准备、执行、沉淀阶段。
</IMPORTANT>
