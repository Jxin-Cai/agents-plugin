# 专项验证目录

仅在 task_type 属于专项验证类时加载。

---

## 支持的专项验证类型

### 1. permission-validation
目标：验证角色差异、按钮/字段可见性、接口权限、越权风险。
重点关注：persona matrix、越权失败信号、字段级与操作级权限。
建议 workflow：`design-lite`

### 2. data-integrity
目标：验证状态机、数据一致性、重复操作、副作用、幂等、补偿与最终一致性。
重点关注：状态流转、重复提交、异步窗口、Data / Side Effect oracle。
建议 workflow：`design-lite`

### 3. integration-resilience
目标：验证下游依赖异常、超时、降级、mock / real 切换策略。
重点关注：依赖策略、降级行为、告警与补偿、可观察信号。
建议 workflow：`design-lite`

---

## 使用原则

1. 专项验证不是默认走完整六阶段；先判断是否需要 full context
2. 若已有脚本/套件足够，优先复用，不从零设计
3. 专项验证更强调 oracle profile 和 risk profile，而不是覆盖所有 happy path
4. 专项验证常常需要更强的角色矩阵、状态前置和依赖策略说明
