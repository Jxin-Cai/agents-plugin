# QA 任务装配路由

## task_type → workflow 映射

| task_type | workflow | 典型输入 |
|-----------|----------|---------|
| `feature-acceptance` | `design-full` | 帮我测新支付流程 |
| `release-readiness` | `release-gate` | 今晚发版前做验证 |
| `regression-batch` / `smoke-check` | `regression-batch` | 跑回归 / run smoke |
| `impact-first` | `impact-first` | 这次改动影响什么 |
| `bug-repro` | `repro-loop` | 复现订单重复提交问题 |
| `permission-validation` / `data-integrity` / `integration-resilience` | `design-lite` | 测权限差异 / 验证幂等 / 降级验证 |
| `automation-maintenance` | `script-maintenance` | fix ts-003 / 沉淀成脚本 |

## 快路由

明确回归 → `run-suite` | 明确修复 → `fix-script` | 明确影响分析 → `impact-analysis`

快路由只做一次确认即直达，不强制完整澄清。

## 装配补问

意图不足时优先问：
1. 哪类 QA 工作？
2. 要交付什么？
3. 主要风险？
4. 有无可复用资产？

## 原则

- 先装配，再选 SOP
- 显式意图优先直达
- 新功能测试只是其中一种场景
- 有资产优先走轻 workflow
- workflow 确定后才加载重型 playbook
