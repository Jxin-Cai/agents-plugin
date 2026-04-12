---
name: e2e
description: QA 工作台入口——先装配任务，再按场景分流到对应 workflow
argument-hint: "<被测功能、发布范围、缺陷现象或回归目标>"
allowed-tools: Read, Write, Glob, Bash(mkdir*), AskUserQuestion, Skill
---

# QA 工作台入口

用户传入的参数：`$ARGUMENTS`

> **条件加载**：入口先读取 `references/intent-assembly-router.md` 做 workflow 分流。只有 workflow 确定后才按需加载对应 playbook。

---

## Step 0: 任务装配与 workflow 分流

### 显式快路由

明确意图时只做一次确认即可直达：
- 回归（"跑回归""run smoke"）→ `run-suite`
- 修复（"fix ts-001""脚本跑不过"）→ `fix-script`
- 影响分析（"这次改动影响什么"）→ `impact-analysis`

### 意图装配

非显式意图时，用 `AskUserQuestion` 按 `references/intent-assembly-router.md` 的装配补问流程收集信息。

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

### workflow 执行入口

- `regression-batch` → `run-suite`
- `impact-first` → `impact-analysis`
- `script-maintenance` → `fix-script` 或 `test-automation-builder`
- 其他 → 进入下方任务落盘流程

---

## Step 1: 初始化与断点恢复

> 仅 `design-full` / `design-lite` / `release-gate` / `repro-loop` 需要此步。

1. 生成 domain 名（kebab-case），`AskUserQuestion` 确认
2. 创建 `.e2e-tests/{domain}/` 及子目录，确保 `_shared/`、`registry/`、`asset-catalog.md`、`quality-ledger.md`、`env/` 存在
3. 按 `references/index-template.md` 初始化 `task/index.md`（如不存在）
4. 以 index.md frontmatter + 实际产物推断接续点
5. 扫描共享资产，`AskUserQuestion` 确认接续阶段

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

1. `task/index.md` 是唯一状态文件，断点恢复以产物为准
2. 每阶段从文件读上下文，不依赖对话记忆
3. 重型任务（scan-context、test-automation-builder）走 subagent
4. 逐阶段停顿等用户确认
5. quality-ledger 存在时加速，缺失不阻塞
6. workflow 可重判，切换时记入决策日志

<IMPORTANT>
默认心智是"先装配 QA 工作，再进入合适 workflow"，不是"所有事情都走新功能测试六阶段"。
</IMPORTANT>
