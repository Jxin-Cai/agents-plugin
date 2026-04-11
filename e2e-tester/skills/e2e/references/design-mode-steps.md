# 设计模式——完整阶段编排指令

> 由 `e2e/SKILL.md` 在确认进入设计模式后条件加载。回归/修复/影响分析不需要此文件。

---

## 上下文管理与资产纪律

> 本流程跨越 6 个阶段。主线不是对话历史，而是当前任务文件和可复用资产目录。

1. **当前任务必须落盘**：`task/task.md` 是本次测试的一级输入；`task/index.md` 是本次任务的唯一状态管理文件（格式见 `index-template.md`）
2. **阶段摘要继续保留**：每个阶段完成后，按 `stage-summary-templates.md` 写入阶段摘要
3. **共享资产优先**：进入澄清、准备、执行、沉淀前，先检索 `.e2e-tests/_shared/**`、`asset-catalog.md`、`registry/`
4. **quality-ledger 是加速缓存**：存在时提供历史经验加速；缺失时 fallback 到默认值执行，不阻塞
5. **下阶段从文件读取**：每个阶段开始时，从 `task/task.md`、`task/index.md` 和前置摘要读取上下文，**不依赖对话记忆**
6. **重型生成走 subagent**：代码扫描（scan-context）、脚本生成（test-automation-builder）必须通过 subagent 执行，避免污染主上下文
7. **逐阶段停顿**：每个阶段结束后必须等待用户确认，不自动跳步
8. **选择题默认允许自定义答案**：使用 `AskUserQuestion` 时，默认允许用户通过内置 Other 提供自定义输入；当多个动作可同时成立时，应使用 `multiSelect: true`

---

## Step 0: 初始化、进度判断与断点恢复

1. 从 `$ARGUMENTS` 中提取测试目标，生成一个业务领域名（2-4 个词，kebab-case，如 `user-auth`、`order-flow`）
2. 使用 `AskUserQuestion` 向用户确认业务领域名
3. 创建或确认工作目录 `.e2e-tests/{domain}/` 及子目录：`task`、`context`、`scenarios`、`prep`、`automation`、`fixtures`、`reports`、`evidence`
4. 确保共享目录存在：`.e2e-tests/_shared/datasets`、`.e2e-tests/_shared/mocks`、`.e2e-tests/_shared/helpers`
5. 如果 `.e2e-tests/registry/` 不存在，创建目录并初始化 `.e2e-tests/registry/index.yaml`：

```yaml
version: 1
updated: {ISO 8601}
domains: {}
```

6. 如果 `.e2e-tests/asset-catalog.md` 不存在，创建初始文件（共享数据集、共享 mock、共享 helper、可复用脚本四个区块）
7. 如果 `.e2e-tests/quality-ledger.md` 不存在，按 `quality-ledger-template.md` 初始化
8. 如果 `.e2e-tests/env/` 不存在，创建目录并按 `env-config-template.md` 初始化默认环境配置
9. 如果 `.e2e-tests/{domain}/task/index.md` 不存在，按 `index-template.md` 初始化该文件
10. **整体进度判断**——以 `task/index.md` frontmatter 和实际文件产物为准：
    - `task/task.md` 是否存在
    - `context/stage-1-summary.md` ~ `stage-4-summary.md` 是否存在
    - `scenarios/TS-*.md` 是否存在
    - `prep/TP-*.md` 是否存在
    - `reports/**/TS-*-run-*.md` 是否存在
    - `automation/*.test.ts` 或 `automation/*.spec.ts` 是否存在
11. **推断当前可接续阶段**：
    - 若无 `task/task.md` → 从 Step 1 开始
    - 若有 task 但无上下文摘要 → 从 Step 2 开始
    - 若有 task + stage-2 摘要但无剧本 → 从 Step 3 开始
    - 若有剧本但无 prep → 从 Step 4 开始
    - 若有 prep 但无报告 → 从 Step 5 开始
    - 若已有报告且结论建议沉淀但无脚本 → 从 Step 6 开始
    - 若全齐 → 向用户说明任务已完成，可选重跑、补测或新建
    - 若 status 为 `archived` → 提示归档，建议新建或激活
12. **归档检测**：`status: completed` 且 `last_updated` 距今超 90 天 → 建议归档
13. 用 `AskUserQuestion` 展示已有产物和建议接续阶段
14. 扫描 `.e2e-tests/_shared/**`、`asset-catalog.md`、`registry/`，报告可复用资产

---

## Step 1: 澄清测试任务

**阶段入口**：读取 `task/index.md`；若已存在 `task/task.md`，先读取并判断是补充、重审还是重写。

使用 Skill 工具调用 `clarify-scope` skill，传入 `$ARGUMENTS` 作为参数。

**阶段完成标志**：`task/task.md` 已生成且用户确认。

**阶段摘要**：按 `stage-summary-templates.md` Stage 1 模板写入 `context/stage-1-summary.md`。

**更新 index.md**：记录 task.md、候选资产、缺失信息。`current_stage: 2`，将 1 加入 `completed_stages`。

**⏸️ `AskUserQuestion` 确认后进入下一步。**

---

## Step 2: 扫描项目上下文

**阶段入口**：读取 `task/task.md`、`task/index.md`、`context/stage-1-summary.md`。

使用 Skill 工具调用 `scan-context` skill。

**阶段完成标志**：`context/` 下有上下文摘要，且用户确认扫描充分。

**阶段摘要**：按 Stage 2 模板写入 `context/stage-2-summary.md`。

**更新 index.md**：记录上下文文件、关键调用链、可复用资产。`current_stage: 3`。

**⏸️ `AskUserQuestion` 确认后进入下一步。**

---

## Step 3: 构建测试剧本

**阶段入口**：读取 `task/task.md`、`task/index.md`、`stage-1-summary.md`、`stage-2-summary.md`。

使用 Skill 工具调用 `test-scenario-gen` skill。

**阶段完成标志**：`scenarios/TS-{NNN}-*.md` 已生成，每个对应一个业务场景，内含多个 case，用户已确认。

**阶段摘要**：按 Stage 3 模板写入 `context/stage-3-summary.md`。

**更新 index.md**：记录剧本列表、case 数、引用资产。`current_stage: 4`。

**⏸️ `AskUserQuestion` 确认后进入下一步。**

---

## Step 4: 准备测试环境与数据

**阶段入口**：读取 `task/task.md`、`task/index.md`、`stage-3-summary.md`。若 `.e2e-tests/env/{env}.yaml` 存在，一并读取目标环境配置。

使用 Skill 工具调用 `test-prep` skill。

**阶段完成标志**：`prep/TP-{NNN}-*.md` 已生成，准备度结论明确（READY / BLOCKED / PARTIAL）。

**阶段摘要**：按 Stage 4 模板写入 `context/stage-4-summary.md`。

**更新 index.md**：记录准备方案、资产决策、readiness。`current_stage: 5`。

**⏸️ `AskUserQuestion` 确认后进入下一步。**

---

## Step 5: 执行测试

**阶段入口**：读取 `task/task.md`、`task/index.md`、`stage-3-summary.md`、`stage-4-summary.md`。

使用 Skill 工具调用 `test-runner` skill。

**阶段完成标志**：`reports/{date}/TS-{NNN}-run-{RRR}.md` 已生成，按 case 给出判定。

**更新 index.md**：记录报告路径、执行方式、case 结果。`current_stage: 6`。

如走路径 B/C 且适合沉淀 → 进入 Step 6。否则：

**⏸️ `AskUserQuestion` 展示结果摘要，询问后续动作。**

---

## Step 6: 沉淀自动化脚本（条件触发）

**触发条件**：Step 5 有足够证据支持沉淀，或用户主动选择。

**阶段入口**：读取 `task/task.md`、`task/index.md`、`stage-3-summary.md`、`stage-4-summary.md`、最近报告。

使用 Skill 工具调用 `test-automation-builder` skill。

**阶段完成标志**：脚本已生成（`.test.ts` 或 `.spec.ts`），`registry/{domain}.yaml` 已更新。

**更新 index.md**：记录脚本路径、覆盖范围、依赖资产。`current_stage: done`，`status: completed`。

展示：脚本路径、覆盖场景/case、复用/新增资产、注册表更新、限制说明。

---

## 接续规则

1. **接续基于产物，不基于记忆**：恢复时从文件读取，不依赖对话历史
2. **frontmatter 与产物冲突时，以产物为准**，修正 frontmatter
3. **缺必要字段停在该阶段补齐**，不跳步
4. **允许回退重做**，保留已有文档，在 index.md"后续修正记录"中标注
5. **不擅自删除旧产物**
