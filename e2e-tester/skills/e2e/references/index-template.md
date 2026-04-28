# 任务索引模板

`index.md` 是单次测试执行（run）的唯一状态文件。

## Frontmatter

```yaml
---
scenario: {scenario-slug}
run_folder: {YYYY-MM-DD}-{run-slug}
domain: {business-domain}
status: active | completed | archived
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DDTHH:mm:ss}
task_type: {feature-acceptance | release-readiness | bug-repro | ...}
workflow: {design-full | design-lite | release-gate | regression-batch | impact-first | repro-loop | script-maintenance}
entry_intent: {用户原始意图}
trigger_source: {发布前 | 缺陷 | 变更 | 巡检}
target_env: {test | staging | prod-like}
evidence_level: {light | standard | strict}
acceptance_source: none | user-text | markdown | external-doc | issue
browser_profile: {shared/env/{env}.yaml#browser 或 inline 摘要}
deploy_profile: {shared/env/{env}.yaml#deploy_scripts 或 none}
evidence_root: .e2e-tests/scenarios/{scenario-slug}/runs/{run-folder}/evidence
last_report: null
export_status: none | recommended | exported | blocked
fix_attempts: 0
# light: 关键截图(Given+Then) + 关键 API 出入参对
# standard: 每步截图 + 完整 API 链 + 错误日志（默认）
# strict: 密集截图序列 + 可访问性快照 + 全量控制台日志
# 默认建议：release-gate→strict, design-lite→light, 其他→standard
current_stage: {1-6 | done}
completed_stages: [1, 2, ...]
---
```

> 旧任务缺新字段时不阻断恢复，首次续跑时补齐。

## 正文结构

```markdown
# {scenario-slug} / {run-folder} QA 任务索引

## Intent Assembly Card
task_type / workflow / entry_intent / trigger_source / target_env / 交付物 / acceptance_source / export_status

## Workflow Decision Log
| 日期 | 决策 | 依据 |

## Acceptance Source
原始验收步骤保存在 task.md；本区只记录 source、step_count、scenario step mapping 路径。

## Browser / Deploy Context
browser_profile / deploy_profile / preflight / stability 参数引用。

## 阶段产物
### Stage 1-6（按阶段列产物文件和状态）

## 候选可复用资产
## 已沉淀资产
## 后续修正记录
| 日期 | 修正阶段 | 修正内容 |
```

## 规则

1. 每阶段结束更新 frontmatter + 产物区块
2. 断点恢复：先读 frontmatter，再验实际文件；冲突以产物为准
3. workflow 切换记入 Decision Log
4. `scenario` 用于定位剧本，`run_folder` 用于定位本次执行，`domain` 保留业务域语义
5. 浏览器证据、报告、导出状态和修复次数只记录引用与摘要，详细内容保存在 evidence/reports/registry
