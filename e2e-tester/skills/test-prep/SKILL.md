---
name: test-prep
description: 为剧本生成测试准备方案，包含资产决策、依赖健康、readiness gate
allowed-tools: Read, Glob, Write, AskUserQuestion
---

# 测试准备器

围绕已确认剧本，生成可执行的准备方案，对资产做复用/定制/新建决策，给执行阶段提供 readiness gate。

## 流程

### Step 0: 检索共享资产

读取 task.md、index.md、已有 TP 文件、`_shared/`、`asset-catalog.md`、`registry/`、`quality-ledger.md`（只提取与当前 domain 相关的环境陷阱和依赖稳定性条目）。

> 若 `task/task.md` 或 `scenarios/` 下的剧本不存在，提示用户先完成前置阶段，不凭空生成准备方案。

### Step 1: 从剧本提取准备项

提取 persona、preconditions、dependencies、oracle_types、reused_assets → 整理：账号、数据、Mock/Fixture、依赖健康、特性开关、隔离策略、清理策略。

### Step 2: 生成 `.e2e-tests/{domain}/prep/TP-{NNN}-{slug}.md`

结构：关联信息、资产决策表（reuse/clone-and-tune/new-task/new-shared）、账号权限、前置数据、依赖策略、依赖健康探测、环境隔离策略、数据准备策略（api-create/db-seed/fixture-import/snapshot-restore）、清理策略、准备度结论（READY/PARTIAL/BLOCKED）。

已有 TP 文件时补齐而非推倒重来。

### Step 3: 共享资产沉淀

任务专用 → `{domain}/fixtures/`；可复用 → `_shared/datasets|mocks|helpers/`

### Step 4: 准备度判定

以下任一成立 → 不判 READY：核心账号未明确、关键前置数据缺失、依赖策略未明确、Mock/Fixture 缺失、副作用不可观测、清理方式不明、real 依赖健康探测未通过、共享环境无隔离机制。

### Step 5: 更新索引并确认

`AskUserQuestion` 确认准备度。

## 约束

1. 准备方案必须落文件
2. 无 readiness 结论不进执行
3. 准备项必须服务于 oracle
4. 数据准备必须可复现
5. 共享环境必须说明隔离
6. 优先复用共享资产

<IMPORTANT>
准备项缺失应阻止执行，而不是边跑边猜。
</IMPORTANT>
