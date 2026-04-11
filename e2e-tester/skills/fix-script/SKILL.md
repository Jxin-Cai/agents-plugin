---
name: fix-script
description: 脚本修复工作流——当回归脚本因产品变更失败时，诊断→修复→验证→更新注册表。当用户说"修脚本"、"fix script"、"脚本失败了"、"脚本跑不过"时触发。
argument-hint: "<失败脚本路径或ID>"
allowed-tools: Read, Glob, Grep, Write, Agent, Bash(git log*), Bash(git diff*), Bash(npx tsx*), Bash(npx playwright*), Bash(npx tsc --noEmit*), AskUserQuestion
---

# 脚本修复工作流

当回归脚本因产品变更失败时，不需要回到 6 阶段设计流程。直接：诊断 → 修复 → 验证 → 更新注册表。

---

## 触发场景

- `run-suite` 执行后用户选择"修复失败脚本"
- 用户直接提供失败脚本路径或 ID
- 用户说"这个脚本跑不过了"

---

## 执行流程

### Step 0: 收集失败上下文

1. 读取失败脚本文件（从 `$ARGUMENTS` 或最近的 `regression-*.md` 报告）
2. 提取脚本 JSDoc 元数据：`@api_endpoints`、`@domain`、`@scenario`、`@cases`
3. 读取 `registry/{domain}.yaml` 中对应条目，提取 `source_paths`、`type`、`api_endpoints`
4. 获取错误输出（从回归报告或重新执行脚本获取）

> **source_paths 和 type 从 registry 读取**，不从 JSDoc 提取——registry 是权威来源，JSDoc 可能遗漏。

### Step 1: 诊断根因

根据 registry 条目的 `source_paths`，检查相关源码的近期变更：

```bash
git log --oneline -10 -- {source_paths}
git diff HEAD~5..HEAD -- {source_paths}
```

交叉比对变更内容与脚本的 `@api_endpoints`，分类根因：

| 根因分类 | 特征 | 处理方式 |
|---------|------|---------|
| **api-change** | 端点 URL、参数、响应结构变了 | 修复脚本请求/断言 |
| **flow-change** | 业务流程步骤变了 | 修复脚本操作顺序 |
| **data-change** | 预期数据格式/值变了 | 修复脚本测试数据和断言 |
| **env-issue** | 环境/基础设施问题 | **不修脚本**，告知用户检查环境 |
| **script-defect** | 脚本自身逻辑缺陷 | 修复脚本逻辑 |

如果根因是 `env-issue`：告知用户这不是脚本问题，建议检查环境，停止。

用 `AskUserQuestion` 向用户展示诊断结果，确认是否继续修复。

### Step 2: 修复脚本

使用 **Agent 工具**（subagent）修复脚本。

Subagent prompt 包含：
- 当前脚本完整内容
- 错误输出
- 相关源码的 git diff
- 诊断的根因分类
- `skills/test-automation-builder/references/script-conventions.md` 中对应类型的规范

Subagent 修复规则：
- 保留 JSDoc 元数据结构，更新 `@last_updated`
- 如端点变了，更新 `@api_endpoints`
- 保持现有测试结构，**只改必要的部分**
- 不删除测试 case；如 case 已废弃，标注 `@deprecated` 注释并告知用户
- `type: api-script` → 不引入 Playwright
- `type: e2e-script` → 可调整 Playwright locator、navigation、断言

### Step 3: 验证修复

重跑修复后的脚本（按 registry 中的 `type` 字段判断执行器，如 registry 缺失则按文件扩展名：`.test.ts` → api-script，`.spec.ts` → e2e-script）：

```bash
# type: api-script
npx tsx {script_path}

# type: e2e-script
npx playwright test {script_path}
```

- **通过** → 进入 Step 4
- **仍然失败** → 第二次尝试修复（允许最多 2 次自动修复）
- **两次都失败** → 向用户展示两次错误，建议人工介入

### Step 4: 更新注册表

更新 `registry/{domain}.yaml`：
- `last_passed` → today
- `fail_count` → 0
- `last_failed` → null
- 如 `api_endpoints` 变了 → 更新
- 如 `source_paths` 需调整 → 更新

同步更新 `registry/index.yaml` 的 `last_updated`。

向用户展示修复结果摘要。

---

## 约束

1. **最多 2 次自动修复** — 两次都失败则交给用户
2. **必须用 subagent** — 保持主上下文清洁
3. **不改测试意图** — 只适配产品变更，不重新设计测试策略
4. **不删除 case** — 废弃的 case 标 `@deprecated`，让用户决定
5. **env-issue 不修脚本** — 环境问题应修环境，不应改脚本来迁就

<IMPORTANT>
fix-script 是"维护"工作流，不是"重新设计"工作流。
如果失败需要重新设计测试策略（比如整个业务流改了），应回到设计模式，不要在 fix-script 里硬修。
</IMPORTANT>
