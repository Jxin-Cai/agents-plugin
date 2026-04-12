# 注册表与套件规范

## 全局索引 — `registry/index.yaml`

```yaml
version: 1
last_updated: {ISO 8601}
domains:
  {domain}:
    file: registry/{domain}.yaml
    script_count: {N}
    last_updated: {ISO 8601}
```

## 域注册表 — `registry/{domain}.yaml`

```yaml
domain: {domain}
scripts:
  ts-{nnn}-{slug}:
    type: api-script | e2e-script
    path: .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.{test|spec}.ts
    scenario: TS-{NNN}
    business_scenario: {描述}
    risk_level: High | Medium | Low
    tags: []
    covers: []
    api_endpoints: []
    source_paths: []        # 业务源码 glob，用于 impact-analysis
    persona: {role}
    last_passed: {YYYY-MM-DD} | null
    last_failed: {YYYY-MM-DD} | null
    fail_count: 0
    stale: false
    suites: []
    automation_confidence: high | medium | low
    created: {YYYY-MM-DD}
    last_updated: {YYYY-MM-DD}
```

必填：type, path, scenario, business_scenario, risk_level, api_endpoints, source_paths, persona, automation_confidence

更新时机：新建（全字段）| PASS（last_passed, fail_count=0）| FAIL（last_failed, fail_count+=1）| 修复（last_passed, fail_count=0, last_updated）

## 套件 — `registry/suites.yaml`

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

scripts 优先于 filter。过滤器支持：risk_level, tags, covers, domain, type, stale。多条件 AND。

## 资产目录 — `asset-catalog.md`

四区块：共享数据集 / 共享 Mock / 共享 Helper / 可复用脚本（跨域参考）。
超 200 行时分片：顶层保留每区块前 10 条 + 总数，完整内容移到 `_shared/{category}/README.md`。
