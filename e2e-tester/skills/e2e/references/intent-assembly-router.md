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

## design-lite 确认

当路由结果为 `design-lite` 时，**必须用 `AskUserQuestion` 向用户确认**：

> 本次识别为专项验证场景，建议走 **design-lite** 最小设计链。
> 这意味着**不走完整 6 阶段，不会沉淀环境数据和自动化脚本**。
> 如果你希望借此 case 沉淀环境配置、测试数据或可复用脚本，建议改走 **design-full**。

- 用户确认 design-lite → 继续
- 用户选择 design-full → 切换 workflow，在决策日志记录原因

## 原则

- 先装配，再选 SOP
- 显式意图优先直达
- 新功能测试只是其中一种场景
- 有资产优先走轻 workflow
- design-lite 必须经用户确认——目标清晰不等于不需要留存
- workflow 确定后才加载重型 playbook
