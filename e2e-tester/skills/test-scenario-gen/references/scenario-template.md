# 专业 E2E 测试剧本模板

以下是标准化的专业 E2E 剧本结构。一个剧本只对应一个业务场景；剧本内部通过多个 case 覆盖该场景下的关键路径、异常、边界和角色差异。

---

## 文件头 Frontmatter

```yaml
---
id: TS-{NNN}
domain: {business-domain}
title: {剧本标题}
goal: {一句话说明本剧本验证的业务目标}
business_scenario: {该剧本对应的单一业务场景}
case_count: {N}
type: functional | regression | smoke
risk_level: High | Medium | Low
persona: {执行该流程的主用户角色}
app: {app-name}
base_url: {base-url}
tags: [{tag1}, {tag2}, {tag3}]
covers: [{feature1}, {feature2}]
oracle_types: [ui, api, data, side-effect, async, idempotency]   # 按需组合
prep_ref: prep/TP-{NNN}-{slug}.md
dependencies:
  - service: {service-name}
    strategy: real | mock | fixture
    mock_config: .e2e-tests/_shared/mocks/{service}.mock.yaml
    fixture_file: .e2e-tests/_shared/datasets/{data-file}.json
reused_assets:
  datasets:
    - .e2e-tests/_shared/datasets/{data-file}.json
  mocks:
    - .e2e-tests/_shared/mocks/{service}.mock.yaml
  helpers:
    - .e2e-tests/_shared/helpers/{helper-file}.ts
  scripts:
    - .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.test.ts
preconditions:
  - {前提条件1}
  - {前提条件2}
out_of_scope:
  - {本次不测的内容1}
  - {本次不测的内容2}
---
```

---

## 正文结构

```markdown
# TS-{NNN}: {剧本标题}

## 背景
- **业务目标**: {为什么要测}
- **业务场景**: {单一业务场景说明}
- **风险等级**: {High / Medium / Low}
- **执行角色**: {persona}
- **准备方案**: `{prep_ref}`

## Business Scenario
- 起点: {从哪里开始}
- 终点: {业务承诺落在哪里}
- 涉及角色 / 状态: {角色和关键状态}
- 关键依赖: {依赖服务与策略}

## Reused Assets
- 数据集: {路径或“无”}
- Mock: {路径或“无”}
- Helper: {路径或“无”}
- 历史脚本: {路径或“无”}

## Case Matrix

| Case | 类型 | 风险 | 主要 Oracle | 自动化优先 | 说明 |
|------|------|------|-------------|-----------|------|
| C1 | Happy Path | High | ui + api + data | 是 | {说明} |
| C2 | Exception | High | api + data | 是 | {说明} |
| C3 | Permission | Medium | ui + data | 视稳定性而定 | {说明} |
| C4 | Async | High | async + data | 是 | {说明} |

---

### Case C1: {case 名称}

**Case Goal**
- {这个 case 要验证的具体业务承诺}

**Case Risk**
- 覆盖风险: {该 case 在防什么问题}
- 若失败影响: {收入 / 数据 / 权限 / 用户体验 / 合规}

**Preconditions**
- 用户角色为 `{persona}`
- 数据状态：{前置数据状态}
- 依赖状态：{关键依赖是否为 real/mock/fixture}
- 当前位于 {起始页面} 页面

**When**
- Step 1: {步骤名称}
  > {精确的操作描述}
  - 等待: {可观测状态变化}
- Step 2: {步骤名称}
  > {精确的操作描述}
  - 等待: {可观测状态变化}

**Then**

#### UI Oracle
- [ ] {界面层面必须看到的结果}

#### API Oracle
- [ ] {接口请求发出且成功 / 状态码 / 返回值}

#### Data Oracle
- [ ] {列表回显 / 状态变化 / 数据未重复 / 数据一致性}

#### Side Effect Oracle
- [ ] {通知已发出 / 导出文件生成 / 审批记录新增 / 库存变化正确}

#### Async Oracle（如涉及异步链路）
- [ ] {异步操作在一致性窗口内完成}
- 轮询策略: {interval}ms × {max_retries} 次，退避方式: {fixed | exponential}
- 一致性窗口: {预期最大等待时间}

#### Idempotency Oracle（如涉及写操作）
- [ ] {同一请求重复提交不产生重复数据}
- [ ] {重复操作不触发重复副作用}

**Evidence Requirements**
- 截图: `ts-{nnn}-c1-step-2.png`
- 接口证据: {接口响应 / trace / 请求摘要}
- 副作用证据: {通知页面、导出文件、列表回显、日志记录等}
- 自动化建议: {适合直接脚本化 / 需先探索 / 暂不适合自动化}

---

### Case C2: {case 名称}

（重复上述结构）

---

## Test Data

| 变量 | 值 | 来源 | 说明 |
|------|-----|------|------|
| {test-user} | test-user-01 | shared-dataset | 测试账号 |
| {base-url} | https://staging.example.com | task-input | 测试环境 |
| {order-id} | ORD-001 | fixture | 测试订单 |
```

---

## 模板使用规则

### 编号规则
- 编号全局唯一递增：TS-001、TS-002 ...
- 文件命名：`TS-{NNN}-{slug}.md`

### 结构规则
- 一个文件只对应一个业务场景
- 一个文件内必须至少有 2 个 case（通常是 Happy Path + 一个关键风险 case）
- 每个 case 必须可单独验证并可在报告中逐个判定
- `Reused Assets` 与 `Test Data` 必须能追溯到任务文件、共享资产目录或当前任务专用资产
