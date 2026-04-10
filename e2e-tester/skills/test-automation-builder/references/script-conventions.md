# 自动化测试资产规范

定义 E2E 自动化脚本的命名、元数据、自描述、注册表字段和适用边界。

核心原则：**沉淀的是纯 API/脚本级自动化，不依赖浏览器。** Playwright 探索中拦截到的接口调用链是脚本的知识来源，但脚本本身直接调接口、验数据。

---

## 文件命名

- 路径: `.e2e-tests/{domain}/automation/ts-{nnn}-{slug}.test.ts`
- 示例: `.e2e-tests/user-auth/automation/ts-001-login-basic.test.ts`
- 扩展名: `.test.ts`（不是 `.spec.ts`，不依赖 Playwright test runner）

---

## 头部元数据（必须）

```typescript
/**
 * @scenario TS-{NNN}
 * @domain {business-domain}
 * @title {中文标题}
 * @business_scenario {单一业务场景}
 * @cases C1, C2, C3
 * @risk {High | Medium | Low}
 * @persona {role}
 * @covers {feature1}, {feature2}
 * @tags {tag1}, {tag2}
 * @oracle {api, data, side-effect}
 * @prep prep/TP-{NNN}-{slug}.md
 * @task task/task.md
 * @api_endpoints {POST /api/xxx}, {GET /api/yyy}
 * @datasets .e2e-tests/_shared/datasets/{dataset}.json
 * @mock_assets .e2e-tests/_shared/mocks/{mock}.yaml
 * @helpers .e2e-tests/_shared/helpers/{helper}.ts
 * @created {YYYY-MM-DD}
 * @last_updated {YYYY-MM-DD}
 * @automation_confidence {high | medium | low}
 *
 * 适用场景:
 * - {适合覆盖的业务路径}
 *
 * 限制:
 * - {当前未自动化覆盖的部分}
 * - {仍需人工验证的 UI 层面}
 *
 * API 调用链来源:
 * - {从哪个 Playwright 探索报告提炼}
 */
```

### 强制字段
- `@business_scenario`
- `@cases`
- `@risk`
- `@persona`
- `@oracle`
- `@prep`
- `@task`
- `@api_endpoints`
- `@datasets`
- `@mock_assets`
- `@helpers`
- `@automation_confidence`
- `限制` 说明（如无可写“无已知限制”）

---

## 脚本结构要求

### 禁止项
- 不得 import playwright 或任何浏览器操作库
- 不得使用 `page`、`browser`、`locator` 等浏览器概念
- 不得依赖截图或 DOM 状态作为断言

### 必须项
- 使用 `fetch` 或项目内 HTTP client 调用 API
- 断言基于接口返回值（HTTP status、response body）
- 状态验证通过查询接口（如 GET 列表、GET 详情）
- 如需认证，通过 API 登录获取 token，不模拟 UI 登录
- 脚本可通过 `npx tsx` 直接运行
- 对多个 case 给出清晰的 case 级输出或断言段落

### 推荐结构

```typescript
// 配置
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

// 辅助函数
async function login(username: string, password: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const data = await res.json();
  return data.token;
}

async function runCaseC1() {
  // Given
  const token = await login('test-user', 'password');

  // When
  const res = await fetch(`${BASE_URL}/api/orders`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${token}`,
    },
    body: JSON.stringify({ /* ... */ }),
  });

  // Then
  assert(res.status === 201, `期望 201，实际 ${res.status}`);
}
```

---

## 断言要求

### 最低标准
- 必须有 API 层断言（HTTP status + response body 关键字段）
- 对于状态流转，必须通过查询接口验证最终状态
- 对异常路径，验证错误码和错误信息符合预期
- 验证“操作没有产生错误副作用”（如重复记录、状态异常）
- 多个 case 时，每个 case 都必须有独立断言块

### 不接受的断言
- 只检查 HTTP 200 不看 body
- 只看文本是否出现在页面上
- 依赖 DOM 结构或 CSS 选择器

---

## 注册表 schema

```yaml
version: 4
updated: {ISO 8601 时间戳}

scripts:
  - id: ts-{nnn}
    domain: {domain}
    scenario: TS-{NNN}-{slug}
    business_scenario: {business_scenario}
    cases: [C1, C2, C3]
    script: {domain}/automation/ts-{nnn}-{slug}.test.ts
    type: api-script
    tags: [{tags}]
    covers: [{covers}]
    risk_level: High | Medium | Low
    oracle_types: [api, data, side-effect]
    api_endpoints:
      - POST /api/xxx
      - GET /api/yyy
    prep: {domain}/prep/TP-{NNN}-{slug}.md
    source_task: {domain}/task/task.md
    datasets:
      - _shared/datasets/{dataset}.json
    mock_assets:
      - _shared/mocks/{mock}.yaml
    helpers:
      - _shared/helpers/{helper}.ts
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
      - {限制1：仍需人工验证的部分}
    source_exploration: {domain}/reports/{date}/TS-{NNN}-run-{RRR}.md
    created: {YYYY-MM-DD}
    last_passed: {YYYY-MM-DD}
    run_command: npx tsx .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.test.ts
```

---

## 资产目录登记要求

`asset-catalog.md` 至少记录：
- 共享数据集：名称、适用业务场景、路径、来源任务
- 共享 mock：名称、覆盖依赖、路径、来源任务
- 共享 helper：用途、路径、来源任务
- 自动化脚本：剧本编号、业务场景、覆盖 case、路径、依赖资产

新增脚本后，必须同步登记其依赖资产，保证后续技能可检索。

---

## 适合自动化沉淀的判断标准

### 适合
- 核心操作有对应的 API 端点
- 状态验证可通过查询接口完成
- 准备数据可通过 API 创建
- 认证流程有 API 入口

### 不适合
- 业务逻辑完全在前端完成（纯前端计算、Canvas 绑定）
- 核心验证依赖视觉效果（渲染正确性、布局）
- 无 API 可调用的纯 UI 交互流（拖拽排序、手势操作）
- 关键结果只能通过页面观察确认

不适合时，应明确记录 limitations，说明哪些部分仍需 Playwright 探索或人工验证。

---

## Subagent 脚本生成 Prompt 模板

启动子 agent 时使用以下 prompt 结构：

```text
你是一个 API 级自动化测试脚本生成器。

可用工具：仅限 Read, Write
约束：只写入指定路径的 .test.ts 文件；不读取 node_modules/；不执行命令

核心原则：
- 生成纯 TypeScript 脚本，用 fetch 调接口，用 assert 验证结果
- 绝对不使用 Playwright 或任何浏览器操作库
- 脚本必须可通过 npx tsx 直接运行
- 尽量复用已有 helper / 数据集 / mock；只有缺口部分才新增

输入：
- 剧本内容（完整 Markdown）
- 准备方案（完整 Markdown）
- 当前任务文件与任务索引
- API 调用链摘要（从报告提炼）
- 可复用 helper / 数据集 / mock（如有）
- 本文档中的头部元数据格式和代码规范

输出：
- 写入 .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.test.ts
- 头部必须包含完整的 JSDoc 元数据
- 使用 fetch 进行 HTTP 调用
- 断言覆盖剧本声明的关键 oracle
- 覆盖多个 case 时，为每个 case 写独立执行函数或断言块
- 包含清理/回滚逻辑（如适用）
- 脚本末尾调用主函数并处理错误退出码
```
