---
name: fix-script
description: 脚本修复——诊断→修复→验证→更新注册表。用于修复已有自动化脚本，或根据 test-runner Path C 的 automation defect 报告修复选择器、等待策略、断言、环境脚本引用。不要用于修产品代码。
argument-hint: "<失败脚本路径或ID>"
allowed-tools: Read, Glob, Grep, Write, Agent, Bash(git log*), Bash(git diff*), Bash(npx tsx*), Bash(npx playwright*), Bash(npx tsc --noEmit*), AskUserQuestion
---

# 脚本修复工作流

回归脚本因产品变更失败时：诊断 → 修复 → 验证 → 更新注册表。不回到六阶段设计流程。

## 流程

### Step 0: 收集失败上下文

读取失败脚本 + JSDoc 元数据 + `.e2e-tests/shared/registry/{domain}.yaml` 条目（source_paths、type、api_endpoints）+ 错误输出。若来自 test-runner Path C，还要读取 run report、evidence manifest、console/network artifacts、retry/fix history 和 Step Mapping。

### Step 1: 诊断根因

```bash
git log --oneline -10 -- {source_paths}
git diff HEAD~5..HEAD -- {source_paths}
```

| 根因 | 处理 |
|------|------|
| api-change | 修脚本请求/断言 |
| flow-change | 修操作顺序 |
| data-change | 修测试数据/断言 |
| env-issue | **不修脚本**，告知用户检查环境 |
| script-defect | 修脚本逻辑 |
| automation-defect-from-exploration | 只修自动化资产：选择器、等待策略、断言、环境脚本引用、auth/reset helper |
| product-defect | **不修产品代码**，保留证据并建议走产品缺陷处理 |
| requirement-oracle unclear | **不修脚本**，回到任务澄清或剧本补 oracle |

`AskUserQuestion` 确认诊断后继续。

### Step 2: subagent 修复

通过 Agent 工具修复。规则：保留 JSDoc 结构、只改必要部分、不删 case（废弃标 @deprecated）、api-script 不引入 playwright。来自探索报告的 automation defect 只能修改 `.e2e-tests/shared/automation/**`、相关 helper/auth/reset 脚本或注册表元数据，不修改产品源码。

### Step 3: 验证

重跑脚本。通过 → Step 4。失败 → 第二次修复。两次都失败 → 交给用户。每次修复都要把修复摘要、验证命令、剩余失败引用回原 report/evidence。

### Step 4: 更新注册表

通过后更新 `.e2e-tests/shared/registry/{domain}.yaml`：
- `last_passed=today`
- `fail_count=0`
- 按需更新 `api_endpoints` / `source_paths`
- 如果修复改变了脚本执行方式或维护策略，同步更新：
  - `execution_mode`
  - `parallel_safe`
  - `recommended_workers`
  - `retry_policy`
  - `trace_policy`
  - `abstraction_mode`

如果这些字段没有变化，保持原值，不要为了“补齐”而盲目重置；如果旧条目缺失这些字段，则按 `skills/e2e/references/registry-conventions.md` 的默认值补齐后，再写入本次确认后的现值。

## 约束

1. 最多 2 次自动修复
2. 必须用 subagent
3. 不改测试意图
4. env-issue 不修脚本
5. product-defect 不修产品代码
6. requirement-oracle unclear 必须回到澄清/剧本阶段
7. 来自 Path C 的修复必须保留 report/evidence/console/network 追溯

<IMPORTANT>
fix-script 是维护工作流。如果需要重新设计测试策略，应回到设计模式。它只修自动化资产和执行契约，不修业务产品代码。
</IMPORTANT>
