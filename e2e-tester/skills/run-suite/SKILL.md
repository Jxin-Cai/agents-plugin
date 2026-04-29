---
name: run-suite
description: 批量回归执行器——按套件/域/标签批量执行已有脚本，生成轻量报告
argument-hint: "<suite名 | domain名 | tag过滤 | 脚本列表>"
allowed-tools: Read, Glob, Write, Skill, Bash(npx tsx*), Bash(npx playwright*), AskUserQuestion
---

# 批量回归执行器

跳过设计仪式。脚本自描述（JSDoc 元数据），直接执行，快速反馈。

## 流程

### Step 0: 解析输入并确认执行计划

从 `$ARGUMENTS` 解析：
- 目标范围：套件名 → `.e2e-tests/shared/registry/suites.yaml` | 域名 → `.e2e-tests/shared/registry/{domain}.yaml` 全部非 stale | 标签/风险过滤 → 遍历匹配 | 显式列表 → 逐个查找
- 执行偏好：`串行` / `{N} 并行` / `只重跑失败项` / `禁用重试` / `开启 trace`

读取：
- `.e2e-tests/shared/registry/suites.yaml`
- `.e2e-tests/shared/registry/{domain}.yaml`
- `.e2e-tests/shared/quality-ledger.md`（若存在，提取时序基线与环境陷阱）
- `.e2e-tests/shared/execution-history.yaml`（若存在，用于智能排序——最近失败优先、flaky 优先、久未执行优先；规则见 `skills/e2e/references/execution-history-template.md`）
- 最近一次 `.e2e-tests/shared/reports/regression-*.md`（仅当用户要求”只重跑失败项”且未显式给脚本列表时）

对每个脚本合并执行元数据（缺失时使用注册表默认值）：
- `execution_mode: serial`
- `parallel_safe: false`
- `recommended_workers: 1`
- `retry_policy: none`
- `trace_policy: on-failure`
- `abstraction_mode: inline`

生成本次执行计划：
- `execution_mode`: `serial` 或 `parallel`
- `workers`: 用户指定值；未指定时并行模式默认取 `min(4, 所有候选脚本 recommended_workers 的最大值)`；串行为 1
- `rerun_scope`: `none` | `failed-only`
- `retry_policy`: `none` | `on-failure-once` | `flaky-only`
- `trace_policy`: `off` | `on-failure` | `on-retry` | `always`

规则：
- 用户要求并行时，`parallel_safe=false` 的脚本必须单独降级为串行批次，并在报告备注中标注 `serial by registry`
- `只重跑失败项` 且最近报告不存在时，退回普通执行并在确认中说明
- 用户未指定 `retry_policy` 时，优先沿用脚本注册表；批量运行不做无限重试

`AskUserQuestion` 单次确认：脚本列表 + 执行模式 + workers + 是否只重跑失败项。

### Step 1: 规划批次并执行

先按以下规则切批：
1. `parallel_safe=false` → 单脚本串行批次
2. `parallel_safe=true` 且 `execution_mode=parallel` → 进入并行池
3. 并行池内按 `type` 分组（`api-script` / `e2e-script`），避免混跑时日志难以归因
4. 每个并行批次的实际 `workers` 取：`min(用户请求 workers, 该批脚本 recommended_workers 的最小值)`

执行规则：
- api-script: `npx tsx`
- e2e-script: `npx playwright test --reporter=json`
- 每脚本记录：exit code / stdout / stderr / 耗时 / PASS|FAIL|ERROR|TIMEOUT
- 脚本间不停顿，失败不中断批次
- 超时阈值：API 60s，E2E 120s

重试与重跑：
- `retry_policy=on-failure-once` → 首次 FAIL/ERROR/TIMEOUT 后立刻重试一次
- `retry_policy=flaky-only` → 仅当失败特征符合 quality-ledger 中已知 flaky 模式或 stderr 呈现时序/环境波动特征时重试一次
- `rerun_scope=failed-only` → 首轮结束后，仅对失败脚本再执行一轮；重跑轮次固定串行（workers=1），便于归因

### Step 2: 轻量报告

按 `references/regression-report-template.md` 生成 `.e2e-tests/shared/reports/regression-{YYYY-MM-DD}-{HHmm}.md`。

报告必须包含：
- 本次 `execution_mode / workers / retry_policy / retry_count / rerun_scope / trace_policy`
- 每脚本 `parallel_safe / abstraction_mode`
- 批次信息（initial-run / failed-only rerun）
- 被强制串行的脚本及原因

一行一脚本摘要，仅失败展开详情。

### Step 3: 更新注册表与执行历史

更新 `.e2e-tests/shared/registry/{domain}.yaml`：
- PASS → `last_passed=today, fail_count=0`
- FAIL/TIMEOUT → `last_failed=today, fail_count+=1`
- 如果本次通过用户覆盖了 `retry_policy / trace_policy / execution_mode`，只在报告中记录，不回写覆盖注册表默认值

同步更新 `.e2e-tests/shared/registry/index.yaml` 的 `last_updated`。

更新 `.e2e-tests/shared/execution-history.yaml`（不存在时按 `skills/e2e/references/execution-history-template.md` 创建）：
- 每个执行过的脚本追加 `recent` 记录（date、result、duration_ms、batch、retry、failure_category）
- 重算 `stats`（total_runs、pass_count、fail_count、pass_rate、avg_duration_ms、consecutive_fails、flaky_score）
- 容量控制：每脚本 recent 最多 20 条

### Step 4: 展示结果

`AskUserQuestion`（multiSelect）：完成 / 修复失败（→ fix-script）/ 重跑失败 / 查看报告。

若存在以下情况，推荐项优先展示：
- 有失败脚本且尚未执行 `failed-only` 重跑 → 推荐“重跑失败”
- 失败归因偏向脚本问题 → 推荐“修复失败”

### 落盘检查

确认以下文件已写入/更新：
- `.e2e-tests/shared/reports/regression-{YYYY-MM-DD}-{HHmm}.md`（报告）
- `.e2e-tests/shared/registry/{domain}.yaml`（已更新）
- `.e2e-tests/shared/execution-history.yaml`（已更新）

缺失则补写。

## 约束

1. 不需要 task.md/scenario/prep
2. 脚本必须在 `.e2e-tests/shared/registry/` 中有注册
3. 不做 readiness gate
4. 只用轻量报告
5. quality-ledger 缺失不阻塞
6. 并行只是一种执行优化，不能覆盖 `parallel_safe=false` 的注册表约束
7. 失败重跑只用于加速定位，不替代 `fix-script` 的深入修复

<IMPORTANT>
回归目标是"快速知道哪里坏了"，不是深度分析。保持轻量，但执行计划和重跑/并行信息必须可追溯。
</IMPORTANT>

