---
name: fix-script
description: 脚本修复——诊断→修复→验证→更新注册表
argument-hint: "<失败脚本路径或ID>"
allowed-tools: Read, Glob, Grep, Write, Agent, Bash(git log*), Bash(git diff*), Bash(npx tsx*), Bash(npx playwright*), Bash(npx tsc --noEmit*), AskUserQuestion
---

# 脚本修复工作流

回归脚本因产品变更失败时：诊断 → 修复 → 验证 → 更新注册表。不回到六阶段设计流程。

## 流程

### Step 0: 收集失败上下文

读取失败脚本 + JSDoc 元数据 + `.e2e-tests/registry/{domain}.yaml` 条目（source_paths、type、api_endpoints）+ 错误输出。

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

`AskUserQuestion` 确认诊断后继续。

### Step 2: subagent 修复

通过 Agent 工具修复。规则：保留 JSDoc 结构、只改必要部分、不删 case（废弃标 @deprecated）、api-script 不引入 playwright。

### Step 3: 验证

重跑脚本。通过 → Step 4。失败 → 第二次修复。两次都失败 → 交给用户。

### Step 4: 更新注册表

`last_passed=today, fail_count=0`，按需更新 `.e2e-tests/registry/{domain}.yaml` 中的 api_endpoints/source_paths。

## 约束

1. 最多 2 次自动修复
2. 必须用 subagent
3. 不改测试意图
4. env-issue 不修脚本

<IMPORTANT>
fix-script 是维护工作流。如果需要重新设计测试策略，应回到设计模式。
</IMPORTANT>
