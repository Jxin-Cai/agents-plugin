# 设计模式阶段编排

> 仅 `design-full` / `design-lite` 时加载。回归/修复/影响分析不需要。

## 纪律

1. `task/task.md` 是一级输入；`task/index.md` 是唯一状态文件
2. 每阶段完成后按 `stage-summary-templates.md` 写摘要到 `.e2e-tests/{domain}/context/stage-{N}-summary.md`
3. 共享资产优先：先查 `.e2e-tests/_shared/`、`.e2e-tests/asset-catalog.md`、`.e2e-tests/registry/`
4. 每阶段从文件读上下文，不依赖对话记忆
5. 重型任务走 subagent（scan-context、test-automation-builder）
6. 逐阶段停顿等用户确认
7. quality-ledger 缺失不阻塞
8. `design-lite` 不追求形式完整——可跳过不必要阶段，在决策日志中说明
9. **每步结束时执行落盘检查**——用 Glob 确认产物文件存在，缺失则补写

## Step 0: 初始化与断点恢复

1. 生成 domain（kebab-case），`AskUserQuestion` 确认
2. 创建域目录（同 e2e/SKILL.md Step 1 的 mkdir -p 列表，共 8 个子目录）
3. 确保全局资产存在（`.e2e-tests/_shared/`、`.e2e-tests/registry/index.yaml`、`.e2e-tests/asset-catalog.md`、`.e2e-tests/quality-ledger.md`、`.e2e-tests/env/`）——不存在时创建空结构
4. 按 `index-template.md` 初始化 `.e2e-tests/{domain}/task/index.md`（从 task.md 读取 `evidence_level` 写入 frontmatter，缺失时留空由 test-runner 补问）
5. 以 frontmatter + 实际产物推断接续点：
   - 无 task.md → Step 1
   - 有 task 无 workflow → Step 1 补装配
   - 有 stage-1 无上下文 → Step 2
   - 有上下文无剧本 → Step 3
   - 有剧本无 prep → Step 4
   - 有 prep 无报告 → Step 5
   - 有报告无脚本 → Step 6
   - 全齐 → 完成
6. `AskUserQuestion` 确认接续阶段

## Step 1: 任务装配与澄清

调用 `clarify-scope`。完成标志：task.md 生成 + workflow 明确 + evidence_level 确定。

写摘要到 `.e2e-tests/{domain}/context/stage-1-summary.md`，更新 `.e2e-tests/{domain}/task/index.md`（current_stage: 2）。

**落盘检查**：确认以下文件存在：
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`
- `.e2e-tests/{domain}/context/stage-1-summary.md`

## Step 2: 扫描上下文

调用 `scan-context`。完成标志：context/ 有摘要。

写摘要到 `.e2e-tests/{domain}/context/stage-2-summary.md`，更新 `.e2e-tests/{domain}/task/index.md`（current_stage: 3）。

> `design-lite`：目标足够明确时可跳过，在决策日志记录。

**落盘检查**：确认以下文件存在：
- `.e2e-tests/{domain}/context/context-*.md`（至少一个）或 design-lite 跳过记录
- `.e2e-tests/{domain}/context/stage-2-summary.md`

## Step 3: 生成剧本

调用 `test-scenario-gen`。完成标志：scenarios/TS-*.md 生成。

写摘要到 `.e2e-tests/{domain}/context/stage-3-summary.md`，更新 `.e2e-tests/{domain}/task/index.md`（current_stage: 4）。

**落盘检查**：确认以下文件存在：
- `.e2e-tests/{domain}/scenarios/TS-*.md`（至少一个）
- `.e2e-tests/{domain}/context/stage-3-summary.md`

## Step 4: 准备环境

调用 `test-prep`。完成标志：prep/TP-*.md + readiness 明确。

写摘要到 `.e2e-tests/{domain}/context/stage-4-summary.md`，更新 `.e2e-tests/{domain}/task/index.md`（current_stage: 5）。

**落盘检查**：确认以下文件存在：
- `.e2e-tests/{domain}/prep/TP-*.md`（至少一个）
- `.e2e-tests/{domain}/context/stage-4-summary.md`

## Step 5: 执行测试

调用 `test-runner`。完成标志：reports/ 有报告。

写摘要到 `.e2e-tests/{domain}/context/stage-5-summary.md`，更新 `.e2e-tests/{domain}/task/index.md`（current_stage: 6）。

**落盘检查**：确认以下文件存在：
- `.e2e-tests/{domain}/reports/` 下有报告文件
- `.e2e-tests/{domain}/context/stage-5-summary.md`

## Step 6: 沉淀（条件触发）

调用 `test-automation-builder`。完成标志：脚本生成 + registry 更新。

写摘要到 `.e2e-tests/{domain}/context/stage-6-summary.md`，更新 `.e2e-tests/{domain}/task/index.md`（status: completed）。

**落盘检查**：确认以下文件存在：
- `.e2e-tests/{domain}/automation/ts-*.ts`（至少一个）
- `.e2e-tests/registry/{domain}.yaml`
- `.e2e-tests/{domain}/context/stage-6-summary.md`

## 接续规则

- 接续基于产物，不基于记忆
- frontmatter 与产物冲突时以产物为准
- 允许回退重做，在决策日志标注
- workflow 可调整，记录切换原因
