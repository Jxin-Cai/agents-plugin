# 任务索引模板

`index.md` 是单次测试执行（run）的唯一状态文件。

## Frontmatter 字段

| 字段 | 说明 |
|------|------|
| scenario | scenario-slug |
| run_folder | {YYYY-MM-DD}-{run-slug} |
| domain | 业务域 |
| status | active / completed / archived |
| created | YYYY-MM-DD |
| last_updated | ISO 8601 |
| task_type | feature-acceptance / release-readiness / bug-repro / ... |
| workflow | design-full / design-lite / release-gate / regression-batch / impact-first / repro-loop / script-maintenance |
| entry_intent | 用户原始意图 |
| trigger_source | 发布前 / 缺陷 / 变更 / 巡检 |
| target_env | test / staging / prod-like |
| evidence_level | light / standard / strict |
| acceptance_source | none / user-text / markdown / external-doc / issue |
| browser_profile | shared/env/{env}.yaml#browser 或 inline |
| deploy_profile | shared/env/{env}.yaml#deploy_scripts 或 none |
| evidence_root | .e2e-tests/scenarios/{scenario}/runs/{run}/evidence |
| last_report | 报告路径或 null |
| export_status | none / recommended / exported / blocked |
| fix_attempts | 修复次数 |
| current_stage | 1-6 / done |
| completed_stages | [1, 2, ...] |

> evidence_level 说明：light=关键截图+关键API对 / standard=每步截图+完整API链+错误日志 / strict=密集截图+可访问性快照+全量日志。默认建议：release-gate→strict, design-lite→light, 其他→standard。
> 旧任务缺新字段时不阻断恢复，首次续跑时补齐。

## 正文结构

1. **Intent Assembly Card** — task_type / workflow / entry_intent / trigger_source / target_env / 交付物 / acceptance_source / export_status
2. **Workflow Decision Log** — `| 日期 | 决策 | 依据 |`
3. **Acceptance Source** — source / step_count / scenario step mapping 路径引用
4. **Browser / Deploy Context** — browser_profile / deploy_profile / preflight / stability 参数引用
5. **Stage 1-6 产物** — 按阶段列产物文件和状态
6. **候选可复用资产**
7. **已沉淀资产**
8. **后续修正记录** — `| 日期 | 修正阶段 | 修正内容 |`

## 规则

1. 每阶段结束更新 frontmatter + 产物区块
2. 断点恢复：先读 frontmatter，再验实际文件；冲突以产物为准
3. workflow 切换记入 Decision Log
4. `scenario` 定位剧本，`run_folder` 定位本次执行，`domain` 保留业务域语义
5. 证据、报告、导出状态和修复次数只记录引用与摘要，详细内容在 evidence/reports/registry
