# 注册表与套件规范

## 全局索引 — `shared/registry/index.yaml`

```yaml
version: 1
last_updated: {ISO 8601}
domains:
  {domain}:
    file: shared/registry/{domain}.yaml
    script_count: {N}
    last_updated: {ISO 8601}
```

## 域注册表 — `shared/registry/{domain}.yaml`

```yaml
domain: {domain}
scripts:
  ts-{nnn}-{slug}:
    type: api-script | e2e-script
    path: .e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.{test|spec}.ts
    scenario: TS-{NNN}
    business_scenario: {描述}
    risk_level: High | Medium | Low
    tags: []
    covers: []
    api_endpoints: []
    source_paths: []        # 业务源码 glob，用于 impact-analysis
    persona: {role}
    execution_mode: serial | parallel
    parallel_safe: true
    recommended_workers: 1
    retry_policy: none | on-failure-once | flaky-only
    trace_policy: off | on-failure | on-retry | always
    abstraction_mode: inline | helper | page-object | keyword
    last_passed: {YYYY-MM-DD} | null
    last_failed: {YYYY-MM-DD} | null
    fail_count: 0
    stale: false
    suites: []
    automation_confidence: high | medium | low
    export_confidence: high | medium | low
    source_run: .e2e-tests/scenarios/{scenario}/runs/{run}
    source_report: runs/{date}-{run-slug}/reports/TS-{NNN}-run-{RRR}.md
    source_evidence:
      - runs/{date}-{run-slug}/evidence/{case-id}/evidence-manifest.md
    covered_acceptance_steps: []
    auth_dependency: null | .e2e-tests/shared/automation/auth/login-{env}.test.ts
    export_notes: []
    created: {YYYY-MM-DD}
    last_updated: {YYYY-MM-DD}
```

必填：type, path, scenario, business_scenario, risk_level, api_endpoints, source_paths, persona, execution_mode, parallel_safe, recommended_workers, retry_policy, trace_policy, abstraction_mode, automation_confidence。由 Path C 导出的脚本还必须填写 export_confidence、source_run、source_report、source_evidence、covered_acceptance_steps、auth_dependency、export_notes

兼容旧条目时，缺失字段按以下默认值理解：
- `execution_mode: serial`
- `parallel_safe: false`
- `recommended_workers: 1`
- `retry_policy: none`
- `trace_policy: on-failure`
- `abstraction_mode: inline`
- `export_confidence: medium`（仅旧条目兼容理解；新导出不得省略）
- `covered_acceptance_steps: []`

更新时机：新建（全字段）| Path C 导出（补 source_run/source_report/source_evidence/covered_acceptance_steps/export_confidence）| PASS（last_passed, fail_count=0）| FAIL（last_failed, fail_count+=1）| 修复（last_passed, fail_count=0, last_updated）

## 套件 — `shared/registry/suites.yaml`

```yaml
suites:
  smoke:
    description: 核心链路快速检查
    scripts: [ts-001, ts-003]    # 显式列表优先
  regression:
    filter: { stale: false }     # 动态过滤
  high-risk:
    filter: { risk_level: High }
```

scripts 优先于 filter。过滤器支持：risk_level, tags, covers, domain, type, stale, execution_mode, parallel_safe, export_confidence。多条件 AND。

## 资产目录 — `shared/asset-catalog.md`

四区块：共享数据集 / 共享 Mock / 共享 Helper / 可复用脚本（跨域参考）。
超 200 行时分片：顶层保留每区块前 10 条 + 总数，完整内容移到 `shared/{category}/README.md`。
