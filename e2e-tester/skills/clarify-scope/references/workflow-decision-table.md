# Workflow 决策表

用于 `clarify-scope` 在任务装配后决定后续 SOP。

---

## 决策规则

| 条件 | 推荐 workflow | 说明 |
|------|----------------|------|
| 新功能 / 新流程 / 策略不清 | `design-full` | 需要完整六阶段对齐 |
| 专项验证（权限 / 数据 / 集成）且目标明确 | `design-lite` | 不默认走完整六阶段 |
| 发布前验证 | `release-gate` | 优先 impact + run-suite + targeted verification |
| 批量回归 / smoke / 套件执行 | `regression-batch` | 直接复用已有脚本资产 |
| 先问影响范围再决定测试集 | `impact-first` | 先做影响分析 |
| 缺陷复现 / 证据链优先 | `repro-loop` | 优先 Path C 探索 |
| 修脚本 / 沉淀脚本 | `script-maintenance` | 直达 fix-script 或 automation-builder |

---

## 决策原则

1. 能直达已有资产就不强行走完整设计模式
2. workflow 选择要写入任务文件和 index.md
3. 如果 workflow 证据不足，用 `AskUserQuestion` 确认，而不是主观猜测
4. 用户显式指定 workflow 时，优先遵从用户意图
