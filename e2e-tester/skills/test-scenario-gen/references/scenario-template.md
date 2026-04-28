# 剧本模板

一个剧本 = 一个业务场景 × 多个 case × oracle 矩阵 × 证据要求。

剧本文件位置：`.e2e-tests/scenarios/{scenario-slug}/scenario.md`

## Frontmatter

```yaml
---
id: TS-{NNN}
domain: {business-domain}
scenario: {scenario-slug}
title: {标题}
goal: {一句话业务目标}
business_scenario: {单一业务场景}
case_count: {N}
type: functional | regression | smoke
risk_level: High | Medium | Low
persona: {主角色}
app: {app-name}
base_url: {base-url}
tags: [{tag1}, {tag2}]
covers: [{feature1}, {feature2}]
oracle_types: [ui, api, data, side-effect, async, idempotency]
prep_ref: runs/{date}-{run-slug}/prep/TP-{NNN}-{slug}.md
dependencies:
  - service: {name}
    strategy: real | mock | fixture
    mock_config: {path}
    fixture_file: {path}
reused_assets:
  datasets: []
  mocks: []
  helpers: []
  scripts: []
preconditions: []
acceptance_source_type: none | user-text | markdown | external-doc | issue
acceptance_step_count: 0
out_of_scope: []
---
```

## 正文结构

```markdown
# TS-{NNN}: {标题}

## 背景
业务目标 / 场景 / 风险 / 角色 / 准备方案引用

## Business Scenario
起点 → 终点 → 涉及角色/状态 → 关键依赖

## Reused Assets
数据集 / Mock / Helper / 历史脚本

## Acceptance Source
- source_type: none | user-text | markdown | external-doc | issue
- source_ref: task.md#acceptance-source 或外部引用
- raw_steps_preserved_in: runs/{date}-{run-slug}/task.md

## Step Mapping
| Step Ref | 原始验收步骤 | 覆盖 Case | Oracle | Evidence Requirement | 状态 |
|----------|--------------|-----------|--------|----------------------|------|
| AS-001 | {原始步骤} | C1 | ui/api/data | screenshot + network | mapped |

## Case Matrix
| Case | 类型 | 风险 | 主要 Oracle | 自动化优先 | 说明 |

---

### Case C1: {名称}

**Goal** / **Risk** / **Preconditions** / **Acceptance Step Refs**

**When**
- Step 1: {操作} → 等待: {可观测变化}

**Then**
- UI Oracle: [ ]
- API Oracle: [ ]
- Data Oracle: [ ]
- Side Effect Oracle: [ ]
- Async Oracle: [ ] （含轮询策略和一致性窗口）
- Idempotency Oracle: [ ]

**Evidence Requirements**
截图 / 接口证据 / 副作用证据 / 自动化建议

## Test Data
| 变量 | 值 | 来源 | 说明 |

## Data Matrix（可选，数据驱动时使用）
```yaml
data_matrix:
  - case_ref: C1
    variants: [{name, data, expected}]
    source: {外部 JSON 路径}
```
```

## 规则

- 编号全局唯一
- 一文件一业务场景，至少 2 个 case
- 每个 case 可独立判定
- Reused Assets 和 Test Data 必须可追溯
- Acceptance Source 必须通过 Step Mapping 关联到 case/oracle/evidence，缺 oracle 的步骤不得判定为可执行 PASS
- 已有 scenario.md 时追加 case 而非推倒重来
