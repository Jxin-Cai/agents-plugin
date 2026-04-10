# 自动化测试资产规范

定义 E2E 自动化脚本的命名、元数据、自描述、注册表字段和适用边界。

核心原则：沉淀两种类型的自动化测试：**API 脚本**（纯接口，`.test.ts`，不依赖浏览器）和 **E2E 脚本**（Playwright 混合流，`.spec.ts`，API + UI 验证）。Playwright 探索中拦截到的接口调用链是脚本的知识来源，但脚本本身直接调接口、验数据。

---

## 文件命名

- 路径: `.e2e-tests/{domain}/automation/ts-{nnn}-{slug}.test.ts`
- 示例: `.e2e-tests/user-auth/automation/ts-001-login-basic.test.ts`
- 扩展名: `.test.ts`（不是 `.spec.ts`，不依赖 Playwright test runner）

---

## E2E 脚本命名

- 路径: `.e2e-tests/{domain}/automation/ts-{nnn}-{slug}.spec.ts`
- 示例: `.e2e-tests/user-auth/automation/ts-002-login-mfa.spec.ts`
- 扩展名: `.spec.ts`（使用 Playwright Test Runner）

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

> API 脚本和 E2E 脚本使用相同的 JSDoc 元数据格式。E2E 脚本额外增加 `@type e2e-script`（API 脚本为 `@type api-script`，可省略）。

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
- `限制` 说明（如无可写"无已知限制"）

---

## 脚本结构要求

### 禁止项（仅 `api-script`）
- 不得 import playwright 或任何浏览器操作库
- 不得使用 `page`、`browser`、`locator` 等浏览器概念
- 不得依赖截图或 DOM 状态作为断言

### E2E 脚本结构要求（`e2e-script`）

**必须项**：
- 使用 Playwright Test Runner 结构（`test.describe`、`test`、`test.beforeAll`）
- 可使用 `page`、`browser`、`locator`、`expect` 等 Playwright API
- 可在同一测试中混合 `page.request` API 调用和 UI 交互
- 可通过 `npx playwright test {path}` 运行
- 头部元数据格式与 API 脚本一致

**推荐**：
- 数据准备和状态验证优先用 API 调用（`page.request` 或 `test.beforeAll` 中的 fetch）
- UI 交互只用于无 API 替代的操作（文件上传、拖拽、多步表单向导）和视觉确认
- 每个 case 仍需独立断言块

**推荐结构**：

```typescript
import { test, expect } from '@playwright/test';

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';

test.describe('TS-002: MFA 登录流程', () => {
  let token: string;

  test.beforeAll(async ({ request }) => {
    // API 准备数据
    const res = await request.post(`${BASE_URL}/api/test/seed-user`, {
      data: { username: 'mfa-user', mfa_enabled: true }
    });
    expect(res.ok()).toBeTruthy();
  });

  test('C1: MFA 正常登录', async ({ page }) => {
    // UI 操作（无法绕过 UI）
    await page.goto(`${BASE_URL}/login`);
    await page.fill('[name=username]', 'mfa-user');
    await page.fill('[name=password]', 'password');
    await page.click('button[type=submit]');
    
    // MFA 验证（纯 UI 交互）
    await page.fill('[name=mfa-code]', '123456');
    await page.click('button[type=submit]');
    
    // API 验证结果
    await expect(page).toHaveURL(/dashboard/);
    const session = await page.request.get(`${BASE_URL}/api/auth/session`);
    expect(session.ok()).toBeTruthy();
    const data = await session.json();
    expect(data.mfa_verified).toBe(true);
  });
});
```

### 必须项
- 使用 `fetch` 或项目内 HTTP client 调用 API
- 断言基于接口返回值（HTTP status、response body）
- 状态验证通过查询接口（如 GET 列表、GET 详情）
- 如需认证，通过 API 登录获取 token，不模拟 UI 登录
- 脚本可通过 `npx tsx` 直接运行
- 对多个 case 给出清晰的 case 级输出或断言段落
- **如需加载 mock 配置，使用约定的 mock-loader**（见 mock-strategy.md 中的运行时集成约定）

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
- 验证"操作没有产生错误副作用"（如重复记录、状态异常）
- 多个 case 时，每个 case 都必须有独立断言块

### 不接受的断言
- 只检查 HTTP 200 不看 body
- 只看文本是否出现在页面上
- 依赖 DOM 结构或 CSS 选择器

---

## 注册表架构（分片）

注册表从单文件 `registry.yaml` 改为**按 domain 分片**：

```
.e2e-tests/registry/
├── index.yaml          # 全局索引
├── user-auth.yaml      # domain 注册表
├── order-flow.yaml
├── payment-checkout.yaml
└── suites.yaml         # 命名套件定义
```

### 全局索引 `registry/index.yaml`

```yaml
version: 1
updated: {ISO 8601}
domains:
  user-auth:
    file: user-auth.yaml
    script_count: 3
    last_updated: {ISO 8601}
  order-flow:
    file: order-flow.yaml
    script_count: 2
    last_updated: {ISO 8601}
```

### 域注册表 `registry/{domain}.yaml`

```yaml
domain: {domain}
updated: {ISO 8601}

scripts:
  - id: ts-{nnn}
    scenario: TS-{NNN}-{slug}
    business_scenario: {business_scenario}
    cases: [C1, C2, C3]
    script: {domain}/automation/ts-{nnn}-{slug}.test.ts
    type: api-script | e2e-script
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
    source_paths:
      - src/modules/{module}/**
      - src/api/{endpoint}.ts
    created: {YYYY-MM-DD}
    last_passed: {YYYY-MM-DD}
    stale: false
    last_failed: null         # set by run-suite on failure
    fail_count: 0             # consecutive failure count
    suites: []                # which named suites include this script
    run_command: npx tsx .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.test.ts    # api-script
    # 或: npx playwright test .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.spec.ts  # e2e-script
```

### 关键字段说明

**`source_paths`**（新增）：
- 记录该脚本覆盖的**业务源码路径 glob 列表**
- 来源：scan-context 扫描时建立的"源码路径 → 服务/功能映射"，由 test-automation-builder 在生成脚本时回填
- 用途：**变更影响分析**（impact-analysis）根据 git diff 的文件列表匹配此字段，推导需要回归的脚本
- 格式：glob 模式（如 `src/modules/order/**`、`src/api/auth/*.ts`）

### 注册表操作规则

1. **新增脚本**：写入 `registry/{domain}.yaml`，同步更新 `registry/index.yaml` 的 `script_count` 和 `last_updated`
2. **检索复用**：先读 `registry/index.yaml` 找到目标 domain，再读对应域注册表；跨 domain 检索时需读 `asset-catalog.md`
3. **过期标记**：`last_passed` 距今超过 90 天 → 自动标记 `stale: true`；stale 脚本在路径决策时降低优先级但不删除
4. **兼容旧版**：若发现根目录存在旧的 `registry.yaml`（单文件），应迁移到分片结构

---

## 套件定义

`.e2e-tests/registry/suites.yaml` 定义命名套件，用于 `run-suite` 批量回归。

```yaml
version: 1
updated: {ISO 8601}

suites:
  smoke:
    description: 部署后冒烟测试
    scripts:                      # 显式脚本列表
      - user-auth/automation/ts-001-login-basic.test.ts
      - order-flow/automation/ts-001-create-order.test.ts
    estimated_duration: 2m

  core-regression:
    description: 核心回归（High risk 脚本）
    scripts: []                   # 空 = 使用动态过滤
    risk_filter: [High]
    domains_filter: []
    tags_filter: []
    estimated_duration: 10m

  payment-chain:
    description: 支付链路专项
    scripts: []
    risk_filter: []
    domains_filter: [payment-checkout, order-flow]
    tags_filter: [payment]
    estimated_duration: 5m
```

### 套件解析规则

1. `scripts` 非空 → 使用显式列表
2. `scripts` 为空 → 从全部域注册表中，按 `risk_filter` + `domains_filter` + `tags_filter` 动态匹配
3. 多个过滤器取交集
4. `stale: true` 的脚本降低优先级但不排除
5. impact-analysis 可输出建议套件配置

---

## 剧本与脚本的关系

> **剧本是设计阶段的中间产物，脚本 JSDoc 是活规格。**

- 剧本（`scenarios/TS-*.md`）在设计模式 Stage 3 中用于与用户对齐测试策略
- 脚本生成（Stage 6）后，脚本头部的 JSDoc 元数据（`@business_scenario`、`@cases`、`@oracle`、`@risk` 等）承载了剧本 80% 的信息
- **回归模式不要求剧本存在**，不检查剧本-脚本同步
- 需要理解脚本意图时，优先读 JSDoc 元数据；只有追溯原始设计决策时才读剧本
- 剧本文件在设计完成后定性为"历史参考"，不再是活产物

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
你是一个自动化测试脚本生成器。

生成类型：{api-script | e2e-script}

可用工具：仅限 Read, Write
约束：只写入指定路径的脚本文件；不读取 node_modules/；不执行命令

核心原则：
【当 type = api-script 时】
- 生成纯 TypeScript 脚本（.test.ts），用 fetch 调接口，用 assert 验证结果
- 绝对不使用 Playwright 或任何浏览器操作库
- 脚本必须可通过 npx tsx 直接运行

【当 type = e2e-script 时】
- 生成 Playwright 测试脚本（.spec.ts），使用 test.describe / test 结构
- 数据准备和状态验证优先用 API 调用（page.request 或 beforeAll 中的 fetch）
- UI 交互只用于无 API 替代的操作
- 脚本必须可通过 npx playwright test 运行

【通用】
- 尽量复用已有 helper / 数据集 / mock；只有缺口部分才新增
- 如需加载 mock 配置，使用 _shared/helpers/mock-loader.ts（如存在）

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
