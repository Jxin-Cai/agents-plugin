# 需求型工作中的分析维度

在需求交付模式中，`clarify-requirements` 完成基础澄清后，必须让用户选择本次需求要做哪些分析维度。

## 1. 维度列表

| 维度标识 | 用户看到的名称 | 用途 | 典型产出 | 推荐顺序 |
|---------|---------------|------|---------|---------|
| `prd` | PRD 成文 | 将澄清结果收敛为结构化需求文档 | `prd/prd-*.md` | 1 |
| `story` | Story 拆分 | 将 PRD 拆成 Epic / User Story / 验收标准 | `stories/stories-*.md` | 2 |
| `success-metrics` | 成功指标 | 定义北极星、功能、护栏指标 | `metrics/success-metrics-*.md` | 2 |
| `discovery` | 发现式验证 | 明确问题、假设、证据和实验 | `discovery/discovery-*.md` | 0 或 1 |
| `enterprise-nfr` | 企业级 NFR 深挖 | 深挖性能、可靠性、安全、审计等非功能需求 | `nfr/nfr-*.md` | 0 或 1 |
| `governance` | 监管/治理深挖 | 把行业监管和企业治理要求转成结构化要求 | `governance/governance-*.md` | 0 或 1 |
| `roadmap` | 优先级/路线图定位 | 决定该需求在机会池或路线图中的位置 | `_portfolio/...` 或 `roadmap/` 摘要 | 3 |

## 2. 默认规则

- 基础澄清是必做项，不属于可跳过维度
- `prd` 不是强制默认；如果用户只是想做 discovery、治理或 NFR，可以不生成 PRD
- `story` 依赖 PRD，通常在 `prd` 之后
- `success-metrics` 通常依赖 PRD，但也允许在 discovery 后先定义方向性指标
- `enterprise-nfr` 和 `governance` 既可在 PRD 前深挖，也可在 PRD 后补充到 PRD

## 3. 维度选择后的执行原则

- 只展示被选维度对应的下一步
- 如果用户只选 `prd + enterprise-nfr`，不要推荐 Story 和成功指标
- 如果用户只选 `discovery`，就停在 discovery，不推进到 PRD
- 如果用户后续改变主意，允许增补维度并更新状态文件

## 4. 状态文件要求

需求目录下统一使用：

`_requirements/{YYYY-MM-DD}-{slug}/meta/workbench-state.md`

至少记录：
- `workflow_mode`
- `selected_dimensions`
- `completed_steps`
- `next_recommended_step`
- `artifact_paths`

后续所有需求型 SOP 都应优先读取这个状态文件，再决定继续什么。