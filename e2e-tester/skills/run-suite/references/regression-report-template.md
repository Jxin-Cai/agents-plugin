# 轻量回归报告模板

用于 `run-suite` 批量回归执行。一行一脚本摘要，仅失败展开详情。

文件路径：`.e2e-tests/shared/reports/regression-{YYYY-MM-DD}-{HHmm}.md`

---

## 模板

```markdown
# 回归报告: {suite名 | domain名 | 自定义标签}

- **执行时间**: {YYYY-MM-DD HH:mm}
- **触发方式**: run-suite
- **脚本数**: {N} 个（{passed} PASS / {failed} FAIL / {skipped} SKIP）
- **总耗时**: {duration}
- **执行模式**: serial | parallel
- **workers**: {N}
- **重试策略**: none | on-failure-once | flaky-only
- **实际重试次数**: {N}
- **重跑范围**: none | failed-only | full-suite
- **trace 策略**: off | on-failure | on-retry | always

## 执行摘要

| # | 脚本 | 类型 | 域 | 并行安全 | 抽象模式 | 结果 | 耗时 | 备注 |
|---|------|------|-----|----------|----------|------|------|------|
| 1 | ts-001-login-basic | api-script | user-auth | false | helper | PASS | 1.2s | serial by registry |
| 2 | ts-002-create-order | api-script | order-flow | true | inline | FAIL | 3.4s | retry x1 → 见失败详情 |
| 3 | ts-003-payment-flow | e2e-script | payment | true | page-object | PASS | 8.1s | batch-2 / worker-2 |

## 批次与重跑信息

| 批次 | 脚本 | workers | 来源 | 说明 |
|------|------|---------|------|------|
| batch-1 | ts-001, ts-002 | 2 | initial-run | 首轮并行批次 |
| rerun-1 | ts-002 | 1 | failed-only | 失败重跑 |

## 失败详情

### ts-002-create-order

- **错误类型**: api-change | flow-change | data-change | env-issue | script-defect | unknown
- **退出码**: {exit code}
- **并行上下文**: serial fallback | worker-{N} | rerun-{N}
- **trace 文件**: {trace path or `—`}
- **错误输出**:
```
{stderr / assertion error, 截断至 50 行}
```
- **可能原因**: {简要分析}
- **建议动作**: 调用 fix-script 修复 | 检查环境 | 人工排查

## 注册表更新

| 脚本 | 字段 | 旧值 | 新值 |
|------|------|------|------|
| ts-001 | last_passed | 2026-04-01 | 2026-04-11 |
| ts-002 | last_failed | — | 2026-04-11 |
| ts-002 | retry_policy | none | on-failure-once |
```

---

## 使用规则

1. 轻量报告不替代设计模式的完整报告——仅用于 `run-suite` 批量回归
2. 失败展开部分只包含错误输出和简要分析，不做完整 Oracle 矩阵分析
3. 如需深入分析某个失败，应转入 `fix-script` 或设计模式的 `test-runner`
4. 回归报告的失败分类沿用 6 类归因（api-change / flow-change / data-change / env-issue / script-defect / unknown），但不强制要求归因置信度
5. 如果脚本因 `parallel_safe=false` 被强制串行，应在执行摘要备注或批次信息中明确说明
6. 若未开启 trace，`trace 文件`填 `—`，不要留空
7. `abstraction_mode` 口径与注册表保持一致：`inline | helper | page-object | keyword`
