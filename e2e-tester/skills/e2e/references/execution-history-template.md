# 执行历史模板

`.e2e-tests/shared/execution-history.yaml` — 脚本级执行记录，供 run-suite 智能排序和 flaky 识别。

## 创建时机

- run-suite Step 3 完成后自动创建/更新
- test-runner 阶段 4.5 完成后更新（单脚本执行记录）

## 结构

```yaml
version: 1
last_updated: "2024-01-15"
# 容量控制: 每个脚本最多保留最近 20 条记录
max_records_per_script: 20

scripts:
  ts-001-create-order:
    path: ".e2e-tests/shared/automation/order/ts-001-create-order.spec.ts"
    stats:
      total_runs: 12
      pass_count: 10
      fail_count: 2
      pass_rate: 0.833
      avg_duration_ms: 4500
      last_run: "2024-01-15"
      last_result: PASS
      consecutive_fails: 0        # 连续失败次数（用于排序权重）
      flaky_score: 0.15           # 0~1，越高越不稳定
    recent:  # 最近 N 次执行，newest first
      - date: "2024-01-15"
        result: PASS
        duration_ms: 4200
        batch: "regression-2024-01-15-1430"
        retry: false
      - date: "2024-01-14"
        result: FAIL
        duration_ms: 5100
        batch: "regression-2024-01-14-0900"
        retry: true
        retry_result: PASS
        failure_category: flaky    # product-defect / automation-defect / env-issue / flaky / timeout
```

## 智能排序规则（run-suite 使用）

run-suite Step 1 规划批次时，按以下权重排序脚本：
1. `consecutive_fails > 0` → 最高优先（最近失败的先跑，快速确认是否修复）
2. `flaky_score > 0.3` → 次优先（不稳定脚本需要更多运行数据）
3. `last_result = FAIL` → 中优先
4. 其余按 `risk_level` DESC → `last_run` ASC（风险高优先，久未执行优先）

## Flaky 评分算法

```
flaky_score = (recent 中 PASS→FAIL 或 FAIL→PASS 的翻转次数) / (recent 记录数 - 1)
```

翻转次数越多 → flaky 越高。`retry_result` 与原 `result` 不同也算一次翻转。

## 容量控制

- 每脚本 `recent` 最多 20 条，超出时丢弃最旧的
- 脚本从 registry 删除后，execution-history 中对应条目保留 30 天后清理
- 整体文件超 500 行时，将低活跃脚本（last_run 超过 60 天）的 recent 截断到 5 条

## 读写规则

- **run-suite Step 0**：读取，用于智能排序
- **run-suite Step 3**：写入/更新每个执行过的脚本的 stats + recent
- **test-runner 阶段 4.5**：单脚本执行后追加 recent 记录
- **fix-script**：修复后可重置 `consecutive_fails=0`
