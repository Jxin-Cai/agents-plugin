# E2E 测试质量报告模板

报告的目标不是记录执行流水，而是给出测试结论的可信度说明，并明确本次复用了什么、沉淀了什么。

---

## 报告文件结构

```markdown
# 测试报告: TS-{NNN} — {剧本标题}

## 一、执行结论

- **总体结论**: PASS / FAIL / BLOCKED / PARTIAL
- **执行方式**: 自动化脚本(A) / 生成后执行(B) / Playwright 探索(C)
- **风险等级**: {High / Medium / Low}
- **结论可信度**: High / Medium / Low

## 二、准备度结论

| 项目 | 状态 | 说明 |
|------|------|------|
| 账号与权限 | READY / BLOCKED | ... |
| 前置数据 | READY / BLOCKED | ... |
| Mock / Fixture | READY / BLOCKED | ... |
| 依赖健康 | READY / BLOCKED | ... |
| 清理策略 | READY / PARTIAL | ... |
| **总准备度** | **READY / PARTIAL / BLOCKED** | ... |

## 三、风险覆盖矩阵

| Case | 风险 | 是否执行 | 结果 | 备注 |
|------|------|----------|------|------|
| C1 Happy Path | High | 是 | PASS | ... |
| C2 Exception | High | 是 | FAIL | ... |

## 四、Oracle 完整度

| Oracle 类型 | 是否要求 | 是否验证 | 证据 | 状态 |
|-------------|----------|----------|------|------|
| UI | 是 | 是 | 截图 | ✅ |
| API | 是 | 否 | - | ❌ |
| Data | 是 | 是 | 列表回显 | ✅ |
| Side Effect | 是 | 否 | - | ❌ |
| Async | 否 | - | - | N/A |
| Idempotency | 否 | - | - | N/A |

## 五、Case 执行汇总

| Case | 类型 | 执行方式 | 结果 | 主要证据 | 结论 |
|------|------|----------|------|----------|------|
| C1 | Happy Path | A | PASS | API + Data | 业务承诺成立 |
| C2 | Exception | C | FAIL | API + Error | 错误处理不符合预期 |

## 六、场景详情

### Case C1: {case 名称} — {PASS / FAIL / BLOCKED}

#### Step 1: {步骤名称} — {PASS / FAIL / SKIP}
- 操作: ...
- 观察: ...
- 证据: ...

#### Oracle 判定
- UI: PASS / FAIL / NOT CHECKED
- API: PASS / FAIL / NOT CHECKED
- Data: PASS / FAIL / NOT CHECKED
- Side Effect: PASS / FAIL / NOT CHECKED
- Async: PASS / FAIL / NOT CHECKED
- Idempotency: PASS / FAIL / NOT CHECKED

## 七、失败分析与归因

### 失败 1: Case {N} / Step {N.M}
| 项目 | 内容 |
|------|------|
| 现象 | ... |
| 归因 | {参照 test-runner 中的 5 类归因} |
| 归因置信度 | High / Medium / Low |
| 建议动作 | ... |

## 八、Flaky 观察与治理
- flaky suspicion: none / low / medium / high
- 是否触发自动重试: 是 / 否
- 重试结果: {PASS / FAIL / 未重试}
- flaky 根因分类: {env_unstable / timing / data_pollution / test_defect / 未确定}
- 治理建议: {修复脚本 / 延长一致性窗口 / 增加数据隔离 / 降级为告警 / 无需处理}

## 九、复用 / 新增资产汇总

### 已复用资产
- 数据集: {路径或“无”}
- Mock: {路径或“无”}
- Helper: {路径或“无”}
- 自动化脚本: {路径或“无”}

### 本次新增资产
- 证据文件: {路径或“无”}
- 候选共享数据集 / Mock / Helper: {路径或“无”}
- 候选自动化脚本: {路径或“无”}

## 十、未覆盖项与限制
- 本次未覆盖: ...
- 原因: ...

## 十一、总结与建议
- 证明了什么
- 没证明什么
- 下一步建议
```

---

## 使用规则

1. 准备度为 BLOCKED 时，总体结论不得为 PASS
2. 关键 oracle 缺失时，总体结论不得为 PASS
3. 每个 FAIL 都要归因
4. 每个 case 都要单独给出执行结论
5. 要写出“证明了什么”和“没证明什么”
6. 异步操作超时未达成时，需区分“业务真的失败”和“一致性窗口不够长”
7. flaky 场景必须标注根因分类，不能只写 suspicion level
8. 必须交代“复用了什么、沉淀了什么”，否则报告不完整
