# 测试质量报告模板

目标：给出测试结论的可信度说明，明确复用了什么、沉淀了什么。

```markdown
# 测试报告: TS-{NNN} — {标题}

## 一、执行结论
总体结论 / 执行方式(A/B/C) / 风险等级 / 结论可信度 / 证据级别(light/standard/strict)

## 二、准备度结论
| 项目 | 状态 | 说明 |
（账号权限 / 前置数据 / Mock / 依赖健康 / 清理策略 / 总准备度）

## 三、风险覆盖矩阵
| Case | 风险 | 是否执行 | 结果 | 备注 |

## 四、Oracle 完整度
| Oracle 类型 | 是否要求 | 是否验证 | 证据文件 | 状态 |

> "证据文件"列使用相对路径（如 `evidence/{case-id}/screenshots/then-result.png`），不用自由文本描述。

## 四.5 证据清单

> standard/strict 时必填；light 时可省略（证据少，直接在场景详情中引用）。

| Case | 证据类型 | 文件路径 | 步骤 | 说明 |
|------|----------|----------|------|------|
| C1 | screenshot | evidence/C1/screenshots/given-verified.png | Given | 前置状态 |
| C1 | api | evidence/C1/api/step-01-POST-create-order.json | When-1 | 创建订单 |
| ... | | | | |

## 五、Case 执行汇总
| Case | 类型 | 执行方式 | 结果 | 主要证据 | 结论 |

> "主要证据"列引用证据文件路径。

## 六、场景详情
### Case C1: {名称} — {结果}
步骤 / 操作 / 观察 / 证据 / Oracle 判定

#### 证据引用
| 序号 | 类型 | 文件路径 | 说明 |
（列出该 case 的所有证据文件）

## 七、失败分析与归因
现象 / 归因（6类）/ 置信度 / 建议动作

## 八、Flaky 观察
suspicion / 重试结果 / 根因分类 / 治理建议

## 九、资产汇总
已复用 / 本次新增 / 新沉淀环境信息 / 认证脚本状态

## 十、未覆盖项与限制

## 十一、总结与建议
证明了什么 / 没证明什么 / 下一步
```

## 规则

1. BLOCKED → 总结论不得 PASS
2. 关键 oracle 缺失 → 不得 PASS
3. 每个 FAIL 必须归因
4. 每个 case 单独结论
5. 异步超时需区分"业务失败"和"窗口不够"
6. flaky 必须标根因分类
7. 必须交代复用和沉淀
8. evidence_level=light 时：Oracle 证据允许引用关键截图（Given + Then）而非逐步截图，证据清单章节可省略
9. evidence_level=strict 时：Oracle 证据必须包含 snapshot 文件引用，证据清单章节必填
10. `third-party-noise` 只记录，不单独导致 FAIL；除非能证明它直接破坏业务链路

轻量回归报告见 `skills/run-suite/references/regression-report-template.md`。
