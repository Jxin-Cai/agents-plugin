---
name: run-suite
description: 批量回归执行器——按套件/域/标签批量执行已有脚本，生成轻量报告
argument-hint: "<suite名 | domain名 | tag过滤 | 脚本列表>"
allowed-tools: Read, Glob, Write, Skill, Bash(npx tsx*), Bash(npx playwright*), AskUserQuestion
---

# 批量回归执行器

跳过设计仪式。脚本自描述（JSDoc 元数据），直接执行，快速反馈。

## 流程

### Step 0: 解析输入并确认

从 `$ARGUMENTS` 解析：套件名 → `suites.yaml` | 域名 → `{domain}.yaml` 全部非 stale | 标签/风险过滤 → 遍历匹配 | 显式列表 → 逐个查找。
quality-ledger 存在时读取时序基线和环境陷阱。
`AskUserQuestion` 单次确认脚本列表。

### Step 1: 顺序执行

按 type 选执行器（api-script: `npx tsx`，e2e-script: `npx playwright test --reporter=json`）。
每脚本记录 exit code / stdout / stderr / 耗时 / PASS|FAIL|ERROR|TIMEOUT。
脚本间不停顿，失败不中断批次。超时阈值：API 60s，E2E 120s。

### Step 2: 轻量报告

按 `references/regression-report-template.md` 生成 `.e2e-tests/reports/regression-{YYYY-MM-DD}-{HHmm}.md`。
一行一脚本摘要，仅失败展开详情。

### Step 3: 更新注册表

PASS → last_passed=today, fail_count=0 | FAIL/TIMEOUT → last_failed=today, fail_count+=1

### Step 4: 展示结果

`AskUserQuestion`（multiSelect）：完成 / 修复失败（→ fix-script）/ 重跑失败 / 查看报告。

## 约束

1. 不需要 task.md/scenario/prep
2. 脚本必须在注册表中
3. 不做 readiness gate
4. 只用轻量报告
5. quality-ledger 缺失不阻塞

<IMPORTANT>
回归目标是"快速知道哪里坏了"，不是深度分析。保持轻量。
</IMPORTANT>
