# E2E 测试质量报告模板

报告的目标不是记录执行流水，而是给出测试结论的可信度说明。

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

| 场景 | 风险 | 是否执行 | 结果 | 备注 |
|------|------|----------|------|------|
| Happy Path | High | 是 | PASS | ... |
| Exception | High | 是 | FAIL | ... |

## 四、Oracle 完整度

| Oracle 类型 | 是否要求 | 是否验证 | 证据 | 状态 |
|-------------|----------|----------|------|------|
| UI | 是 | 是 | 截图 | ✅ |
| API | 是 | 否 | - | ❌ |
| Data | 是 | 是 | 列表回显 | ✅ |
| Side Effect | 是 | 否 | - | ❌ |

## 五、场景详情

### Scenario 1: {场景名称} — {PASS / FAIL / BLOCKED}

#### Step 1.1: {步骤名称} — {PASS / FAIL / SKIP}
- 操作: ...
- 观察: ...
- 证据: ...

#### Oracle 判定
- UI: PASS / FAIL
- API: PASS / FAIL / NOT CHECKED
- Data: PASS / FAIL / NOT CHECKED
- Side Effect: PASS / FAIL / NOT CHECKED

## 六、失败分析与归因

### 失败 1: Scenario {N} / Step {N.M}
| 项目 | 内容 |
|------|------|
| 现象 | ... |
| 归因 | {参照 test-runner 中的 5 类归因} |
| 归因置信度 | High / Medium / Low |
| 建议动作 | ... |

## 七、Flaky 观察
- flaky suspicion: none / low / medium / high

## 八、未覆盖项与限制
- 本次未覆盖: ...
- 原因: ...

## 九、总结与建议
- 证明了什么
- 没证明什么
- 下一步建议
```

---

## 使用规则

1. 准备度为 BLOCKED 时，总体结论不得为 PASS
2. 关键 oracle 缺失时，总体结论不得为 PASS
3. 每个 FAIL 都要归因
4. 要写出"证明了什么"和"没证明什么"
