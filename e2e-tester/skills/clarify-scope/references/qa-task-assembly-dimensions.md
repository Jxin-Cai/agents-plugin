# QA 任务装配维度

`clarify-scope` 不再只服务“新功能测试设计”，而要先帮助用户装配这次 QA 工作本身。

---

## 必识别维度

1. `task_type` — 这次属于哪类 QA 工作
2. `objective` — 最终要回答什么问题
3. `trigger_source` — 为什么现在做（发布、缺陷、变更、巡检）
4. `deliverable_type` — 想交付什么（报告、证据、脚本）
5. `scope_in` / `scope_out` — 本轮测什么，不测什么
6. `risk_profile` — 主要担心什么失败
7. `persona_matrix` — 涉及哪些角色/权限差异
8. `state_preconditions` — 需要什么数据/状态前置
9. `dependency_policy` — real / mock / fixture / new asset
10. `oracle_profile` — UI / API / Data / Side Effect / Async / Idempotency
11. `execution_constraints` — 环境、时间窗、证据严格度、是否允许 mock
12. `workflow_candidate` — 当前最适合进入哪条 workflow

---

## 追问原则

1. 先扫描已有资产和历史任务，只问缺口
2. 先识别 task_type，再进入对应的最小问题集
3. 问题必须围绕“装配任务”，不是默认把用户拖进新功能测试设计
4. 输出必须能支撑后续 workflow 决策，而不是停留在口头澄清
