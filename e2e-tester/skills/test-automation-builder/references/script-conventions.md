# 自动化测试资产规范

定义 E2E 自动化脚本的命名、元数据、自描述、注册表字段和适用边界。目标是让脚本成为长期可复用的测试资产，而不是一次性执行代码。

---

## 文件命名

- 路径: `.e2e-tests/{domain}/automation/ts-{nnn}-{slug}.spec.ts`
- 示例: `.e2e-tests/user-auth/automation/ts-001-login-basic.spec.ts`

---

## 头部元数据（必须）

```typescript
/**
 * @scenario TS-{NNN}
 * @domain {business-domain}
 * @title {中文标题}
 * @risk {High | Medium | Low}
 * @persona {role}
 * @covers {feature1}, {feature2}
 * @tags {tag1}, {tag2}
 * @oracle {ui, data, side-effect}
 * @prep prep/TP-{NNN}-{slug}.md
 * @created {YYYY-MM-DD}
 * @last_updated {YYYY-MM-DD}
 * @automation_confidence {high | medium | low}
 *
 * 适用场景:
 * - {适合覆盖的业务路径}
 *
 * 限制:
 * - {当前未自动化覆盖的部分}
 */
```

### 强制字段
- `@risk`
- `@persona`
- `@oracle`
- `@prep`
- `@automation_confidence`
- `限制` 说明（如无可写“无已知限制”）

---

## 代码结构要求

- 外层 describe 对应 Feature
- 内层 describe 对应 Scenario
- 断言必须能映射回剧本中的 oracle
- 如果关键 oracle 无法自动化验证，必须在脚本和注册表中明确限制

---

## 断言要求

### 最低标准
- 不能只有 UI 断言
- 对于关键状态流转，至少补一个 Data / Side Effect / API 层断言
- 对异常路径，必须验证“系统没有产生错误副作用”

### 示例

错误示例：
- 只断言“提交成功” toast 出现

正确示例：
- toast 出现
- 列表中出现新记录
- 状态为“待审核”
- 未产生重复记录

---

## 注册表 schema（增强版）

```yaml
version: 2
updated: {ISO 8601 时间戳}

scripts:
  - id: ts-{nnn}
    domain: {domain}
    scenario: TS-{NNN}-{slug}
    script: {domain}/automation/ts-{nnn}-{slug}.spec.ts
    tags: [{tags}]
    covers: [{covers}]
    risk_level: High | Medium | Low
    oracle_types: [ui, api, data, side-effect]
    prep: {domain}/prep/TP-{NNN}-{slug}.md
    match_keys:
      persona: {role}
      goal: {goal}
      dependencies: [{service-a}, {service-b}]
    dependency_profile:
      real: [{service-a}]
      mock: [{service-b}]
      fixture: [{service-c}]
    automation_confidence: high | medium | low
    limitations:
      - {限制1}
      - {限制2}
    created: {YYYY-MM-DD}
    last_passed: {YYYY-MM-DD}
```

---

## 适合自动化沉淀的判断标准

### 适合
- 准备可重复
- oracle 稳定
- 页面结构稳定
- 核心验证可程序化

### 不适合
- 强依赖人工主观判断
- 强依赖一次性环境或临时数据
- 关键结果无法稳定观测
- 定位器极不稳定且无可靠替代信号

不适合时，应明确记录 limitations，而不是伪装成高质量自动化。

---

## Subagent 脚本生成 Prompt 模板

启动子 agent 时使用以下 prompt 结构：

```text
你是一个 Playwright 测试脚本生成器。

可用工具：仅限 Read, Write
约束：只写入指定路径的 .spec.ts 文件；不读取 node_modules/；不执行命令

输入：
- 剧本内容（完整 Markdown）
- 准备方案（完整 Markdown）
- 可复用 helper（如有）
- 本文档中的头部元数据格式和代码规范

输出：
- 写入 .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.spec.ts
- 头部必须包含完整的 JSDoc 元数据（@scenario, @domain, @risk, @persona, @oracle, @prep, @automation_confidence, 限制）
- 每个 Scenario 对应 test.describe
- 断言必须覆盖剧本声明的关键 oracle
- 使用语义化定位器（getByRole > getByText > getByLabel > locator）
- 禁止 page.waitForTimeout()
```
