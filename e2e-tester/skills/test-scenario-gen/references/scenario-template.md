# 专业 E2E 测试剧本模板

以下是标准化的专业 E2E 剧本结构。剧本必须同时表达：业务目标、风险、准备、场景、oracle 与证据要求。

---

## 文件头 Frontmatter

```yaml
---
id: TS-{NNN}
domain: {business-domain}
title: {剧本标题}
goal: {一句话说明本剧本验证的业务目标}
type: functional | regression | smoke
risk_level: High | Medium | Low
persona: {执行该流程的用户角色}
app: {app-name}
base_url: {base-url}
tags: [{tag1}, {tag2}, {tag3}]
covers: [{feature1}, {feature2}]
oracle_types: [ui, api, data, side-effect]   # 按需组合
prep_ref: prep/TP-{NNN}-{slug}.md
dependencies:
  - service: {service-name}
    strategy: real | mock | fixture
    mock_config: fixtures/mocks/{service}.mock.yaml
    fixture_file: fixtures/{data-file}.json
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
- **风险等级**: {High / Medium / Low}
- **执行角色**: {persona}
- **准备方案**: `{prep_ref}`

## Feature: {功能描述}

### Scenario 1: {场景名称}（Happy Path / Exception / Boundary / Permission）

**场景价值**
- 覆盖风险: {该场景在防什么问题}
- 若失败影响: {收入 / 数据 / 权限 / 用户体验 / 合规}

**Given**
- 用户角色为 `{persona}`
- 数据状态：{前置数据状态}
- 依赖状态：{关键依赖是否为 real/mock/fixture}
- 当前位于 {起始页面} 页面

**When**
- Step 1.1: {步骤名称}
  > {精确的操作描述}
  - 等待: {可观测状态变化}
- Step 1.2: {步骤名称}
  > {精确的操作描述}
  - 等待: {可观测状态变化}

**Then**

#### UI Oracle
- [ ] {界面层面必须看到的结果}
- [ ] {按钮/表格/提示/页面状态}

#### API Oracle
- [ ] {接口请求发出且成功 / 状态码 / 返回值}

#### Data Oracle
- [ ] {列表回显 / 状态变化 / 数据未重复 / 数据一致性}

#### Side Effect Oracle
- [ ] {通知已发出 / 导出文件生成 / 审批记录新增 / 库存变化正确}

**证据要求**
- 截图: `ts-{nnn}-step-1.2.png`
- 若有接口证据: {接口响应 / trace / 请求摘要}
- 若有副作用证据: {通知页面、导出文件、列表回显、日志记录等}

---

### Scenario 2: {场景名称}

（重复上述结构）

---

## 场景矩阵

| 场景 | 类型 | 风险 | 主要 Oracle | 是否自动化优先 |
|------|------|------|-------------|----------------|
| Scenario 1 | Happy Path | High | ui + data + side-effect | 是 |
| Scenario 2 | Exception | High | ui + api | 是 |
| Scenario 3 | Permission | Medium | ui + data | 视稳定性而定 |

## 测试数据

| 变量 | 值 | 说明 |
|------|-----|------|
| {test-user} | test-user-01 | 测试账号 |
| {base-url} | https://staging.example.com | 测试环境 |
| {order-id} | ORD-001 | 测试订单 |
```

---

## 模板使用规则

### 编号规则
- 编号全局唯一递增：TS-001、TS-002 ...
- 文件命名：`TS-{NNN}-{slug}.md`
