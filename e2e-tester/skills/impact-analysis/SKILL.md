---
name: impact-analysis
description: 分析代码变更对已有测试的影响，推导回归范围
allowed-tools: Read, Write, Glob, Grep, Agent, Skill, Bash(git log*), Bash(git diff*), Bash(git show*), AskUserQuestion
---

# 变更影响分析

从 git diff / commit / PR 出发，结合 registry 元数据推导哪些测试需要回归。

## 流程

### Step 1: 收集变更范围

```bash
# 方式 A: commit/branch/PR
git diff {ref}^ {ref} --name-only
# 方式 B: 用户描述 → Grep 搜索相关源码
```

### Step 2: 匹配已有测试

读取 `.e2e-tests/shared/registry/`，四层匹配：
1. **source_paths 直接命中** → P0
2. **API 端点匹配**（变更文件中的端点 → registry api_endpoints）→ P0
3. **tags/covers 模糊匹配** + risk_level High → P1
4. **`.e2e-tests/shared/quality-ledger.md` 活跃失败模式**涉及变更模块 → P2

不确定时用 Explore subagent 快速扫描。

### Step 3: 展示影响报告

`AskUserQuestion` 展示：变更摘要、需回归测试表（优先级/脚本/命中原因/上次结果）、缺少覆盖的风险、建议动作。

### Step 4: 按用户选择执行

- 批量回归 → 调用 `run-suite`
- 新建任务 → 调用 `e2e`
- 仅报告 → 写入 `.e2e-tests/shared/reports/impact-{date}-{slug}.md`

### 落盘检查

若用户选择“仅报告”，确认文件已写入：
- `.e2e-tests/shared/reports/impact-{date}-{slug}.md`

## 约束

1. 直接用 `.e2e-tests/shared/registry/` 元数据 + 实时扫描，不依赖代码快照
2. 模糊匹配标注“建议人工确认”
3. 直接命中才是 P0
4. 展示后等用户确认，不自动执行
