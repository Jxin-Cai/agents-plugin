# 注册表与套件规范

## 全局索引

`shared/registry/index.yaml`：`version` / `last_updated` / `domains.{domain}`: `{file, script_count, last_updated}`

## 域注册表

`shared/registry/{domain}.yaml`，每个脚本条目字段：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| type | enum | ✓ | — | api-script / e2e-script |
| path | string | ✓ | — | 脚本文件路径 |
| scenario | string | ✓ | — | TS-{NNN} |
| business_scenario | string | ✓ | — | 业务场景描述 |
| risk_level | enum | ✓ | — | High / Medium / Low |
| tags | list | | [] | 标签 |
| covers | list | | [] | 覆盖功能 |
| api_endpoints | list | ✓ | — | API 端点列表 |
| source_paths | list | ✓ | — | 业务源码 glob，用于 impact-analysis |
| persona | string | ✓ | — | 角色 |
| execution_mode | enum | ✓ | serial | serial / parallel |
| parallel_safe | bool | ✓ | false | 是否允许并行 |
| recommended_workers | int | ✓ | 1 | 推荐并行度 |
| retry_policy | enum | ✓ | none | none / on-failure-once / flaky-only |
| trace_policy | enum | ✓ | on-failure | off / on-failure / on-retry / always |
| abstraction_mode | enum | ✓ | inline | inline / helper / page-object / keyword |
| automation_confidence | enum | ✓ | — | high / medium / low |
| last_passed | date | | null | |
| last_failed | date | | null | |
| fail_count | int | | 0 | |
| stale | bool | | false | |
| suites | list | | [] | |
| export_confidence | enum | 导出时✓ | medium | high / medium / low |
| source_run | string | 导出时✓ | — | 来源 run 路径 |
| source_report | string | 导出时✓ | — | 来源报告路径 |
| source_evidence | list | 导出时✓ | — | 来源证据路径 |
| covered_acceptance_steps | list | 导出时✓ | [] | 覆盖的验收步骤 |
| auth_dependency | string | | null | 认证脚本路径 |
| export_notes | list | | [] | |
| created | date | | — | |
| last_updated | date | | — | |

## 更新时机

新建（全字段）| Path C 导出（补 source_run/report/evidence/acceptance_steps/export_confidence）| PASS（last_passed, fail_count=0）| FAIL（last_failed, fail_count+=1）| 修复（last_passed, fail_count=0, last_updated）

## 套件

`shared/registry/suites.yaml`：每个 suite 含 `description` + `scripts`（显式列表，优先）或 `filter`（动态过滤）。过滤器支持：risk_level / tags / covers / domain / type / stale / execution_mode / parallel_safe / export_confidence，多条件 AND。

## 资产目录

`shared/asset-catalog.md`：四区块（共享数据集 / 共享 Mock / 共享 Helper / 可复用脚本跨域参考）。超 200 行时分片：顶层保留每区块前 10 条 + 总数，完整内容移到 `shared/{category}/README.md`。
