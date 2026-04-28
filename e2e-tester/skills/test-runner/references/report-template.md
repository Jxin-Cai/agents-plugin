# 测试质量报告模板

目标：给出测试结论的可信度说明，明确复用了什么、沉淀了什么。

```markdown
# 测试报告: TS-{NNN} — {标题}

## 一、执行结论
总体结论 / 执行方式(A/B/C) / 风险等级 / 结论可信度 / 证据级别(light/standard/strict)

## 一.5 执行配置
| 项目 | 值 | 说明 |
|------|----|------|
| execution_mode | serial / parallel | 本次执行模式 |
| parallel_safe | true / false | 脚本或 case 是否允许并行 |
| workers | {N} | 实际并行度；串行时填 1 |
| retry_policy | none / on-failure-once / flaky-only | 本次采用的重试策略 |
| retry_count | {N} | 实际触发的重试次数 |
| rerun_scope | none / failed-only / full-case | 是否进行了失败重跑 |
| trace_policy | off / on-failure / on-retry / always | trace 采集策略 |
| abstraction_mode | inline / helper / page-object / keyword | 当前脚本或沉淀建议的抽象模式 |
| acceptance_source | none / user-text / markdown / external-doc / issue | 验收步骤来源 |
| evidence_root | evidence/{case-id} | 证据根目录 |
| export_status | none / recommended / exported / blocked | 是否建议导出 Playwright 用例 |

> 若某字段由注册表继承，应在说明列标注“registry default”；本次临时覆盖则标注“run override”。

## 二、准备度结论
| 项目 | 状态 | 说明 |
（账号权限 / 前置数据 / Mock / 依赖健康 / 清理策略 / 总准备度）

## 三、风险覆盖矩阵
| Case | Acceptance Steps | 风险 | 是否执行 | 结果 | 备注 |

## 四、Oracle 完整度
| Oracle 类型 | 是否要求 | 是否验证 | 证据文件 | 状态 |

> "证据文件"列使用相对路径（如 `evidence/{case-id}/screenshots/then-result.png`），不用自由文本描述。

## 四.5 证据清单

> standard/strict 时必填；light 时可省略（证据少，直接在场景详情中引用）。

| Case | 证据类型 | 文件路径 | 步骤 | Acceptance Step | 说明 |
|------|----------|----------|------|-----------------|------|
| C1 | screenshot | evidence/C1/screenshots/given-verified.png | Given | AS-000 | 前置状态 |
| C1 | api | evidence/C1/api/step-01-POST-create-order.json | When-1 | AS-001 | 创建订单 |
| C1 | network | evidence/C1/network/step-01-create-order.txt | When-1 | AS-001 | 原始 network 片段 |
| C1 | console | evidence/C1/console/then-error.txt | Then | AS-002 | 控制台错误 |
| C1 | trace | evidence/C1/trace/step-01.zip | When-1 | AS-001 | 首次失败后采集 |
| ... | | | | |

## 五、Case 执行汇总
| Case | 类型 | 执行方式 | 结果 | 主要证据 | 重试/重跑 | 结论 |

> "主要证据"列引用证据文件路径；如发生重试/重跑，在“重试/重跑”列记录 `retry x1`、`rerun failed-only` 等。

## 六、场景详情
### Case C1: {名称} — {结果}
步骤 / Acceptance Step Ref / 操作 / 观察 / 证据 / Console / Network / Oracle 判定

#### 证据引用
| 序号 | 类型 | 文件路径 | 说明 |
（列出该 case 的所有证据文件）

## 七、失败分析与归因
现象 / 归因（product defect、environment defect、data-setup defect、automation defect、requirement-oracle unclear、third-party-noise）/ 置信度 / 建议动作 / trace、console、network 引用（如存在）

## 八、Flaky 观察
suspicion / 首次结果 / 重试结果 / 是否触发 rerun / 根因分类 / 治理建议

## 九、资产汇总
已复用 / 本次新增 / 新沉淀环境信息 / 认证脚本状态 / 推荐注册表回写（execution_mode、trace_policy、abstraction_mode 等）

## 九.5 Playwright 导出建议
| Case | Export Status | 推荐脚本类型 | 前置条件 | 阻塞原因 | 来源证据 |
|------|---------------|--------------|----------|----------|----------|
| C1 | recommended / blocked / none | e2e-script / api-script / auth-script | auth + reset + oracle | {原因} | report + evidence manifest |

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
11. 发生重试、重跑或 trace 采集时，必须在“执行配置”“Case 执行汇总”“失败分析与归因”三个位置至少出现一次
12. 若当前仅做人工探索且尚未沉淀脚本，`abstraction_mode` 可填 `inline`，并在总结中说明是否建议升级为 `helper / page-object / keyword`
13. Path C 报告必须包含 acceptance step ref、console/network artifact、retry/fix history 和 export recommendation

轻量回归报告见 `skills/run-suite/references/regression-report-template.md`。
