# Mock 与打桩策略指南

E2E 测试经常跨多个服务，需要明确每个外部依赖的处理策略。本文档定义 Mock 配置的标准格式和使用场景。

---

## 策略决策矩阵

| 依赖类型 | 策略选择 | 理由 |
|---------|---------|------|
| 被测核心服务 | **real** | 必须验证真实行为 |
| 第三方支付 | **mock** | 不可控，且有资金风险 |
| 短信/邮件服务 | **mock** | 外部服务，且会产生实际发送 |
| 内部微服务（环境稳定） | **real** | 能验证真实集成 |
| 内部微服务（环境不稳定） | **mock** | 避免环境问题干扰测试 |
| 需要特定数据状态 | **fixture** | 预制数据比运行时造数据更可靠 |
| 文件/对象存储 | **fixture** | 预制文件 URL 避免上传依赖 |

> **高级策略**：涉及契约校验、故障注入或有状态依赖时，读取 `references/mock-strategy-advanced.md`。

---

## Mock 配置文件格式

存放路径：`.e2e-tests/{domain}/fixtures/mocks/{service-name}.mock.yaml`

### 基本结构

```yaml
# Mock 配置文件
service: payment-gateway          # 被 Mock 的服务名
description: 模拟支付网关的响应    # 简要说明
base_url: https://pay.internal/api  # 原始服务地址（便于切换回真实服务）

# 默认行为：未匹配到任何规则时
default_response:
  status: 200
  body:
    message: "mock default response"

# 端点规则列表（按顺序匹配，先匹配先生效）
endpoints:

  # 规则 1: 正常支付
  - name: 支付成功
    path: /v1/charges
    method: POST
    request:                        # 可选：匹配条件
      body:
        amount: { lte: 100000 }     # 金额 ≤ 1000 元
    response:
      status: 200
      body:
        id: "ch_mock_001"
        status: "succeeded"
        amount: "{{ request.body.amount }}"
      headers:
        Content-Type: application/json

  # 规则 2: 大额支付失败
  - name: 大额支付拒绝
    path: /v1/charges
    method: POST
    request:
      body:
        amount: { gt: 100000 }      # 金额 > 1000 元
    response:
      status: 402
      body:
        error: "payment_failed"
        message: "Amount exceeds limit"

  # 规则 3: 查询支付状态
  - name: 查询支付结果
    path: /v1/charges/{id}
    method: GET
    response:
      status: 200
      body:
        id: "{{ request.path.id }}"
        status: "succeeded"

  # 规则 4: 模拟超时
  - name: 支付超时
    path: /v1/charges/timeout
    method: POST
    response:
      delay_ms: 30000               # 延迟 30 秒模拟超时
      status: 504
      body:
        error: "gateway_timeout"
```

### 匹配规则

| 条件类型 | 说明 | 示例 |
|---------|------|------|
| `path` | URL 路径匹配（支持 `{param}` 占位） | `/v1/users/{id}` |
| `method` | HTTP 方法 | `GET`、`POST`、`PUT` |
| `request.body` | 请求体字段匹配 | `amount: { gt: 100 }` |
| `request.headers` | 请求头匹配 | `Authorization: "Bearer *"` |
| `request.query` | 查询参数匹配 | `status: "active"` |

### 响应模板

| 字段 | 说明 |
|------|------|
| `status` | HTTP 状态码 |
| `body` | 响应体（支持 `{{ request.* }}` 引用请求数据） |
| `headers` | 响应头 |
| `delay_ms` | 延迟响应（模拟慢接口/超时） |

---

## 运行时集成约定

Mock 配置不只是文档——需要在脚本执行时实际生效。以下定义 mock 在不同场景下的加载方式：

### 方式 1：脚本内 mock helper（推荐，适合纯 API 脚本）

当 `.e2e-tests/_shared/helpers/mock-loader.ts` 存在时，脚本可直接引用：

```typescript
// mock-loader.ts 约定接口
export interface MockConfig {
  service: string;
  endpoints: MockEndpoint[];
}

/**
 * 从 mock YAML 配置生成一个 mock 路由函数
 * 用法：在测试脚本中替代真实 fetch 调用
 */
export function loadMockConfig(yamlPath: string): MockConfig;

/**
 * 创建一个代理 fetch 函数——匹配 mock 规则时返回预设响应，
 * 未匹配时 fallback 到真实请求或抛错
 */
export function createMockFetch(configs: MockConfig[], options?: {
  fallback: 'real' | 'error';
}): typeof fetch;
```

使用示例：

```typescript
import { loadMockConfig, createMockFetch } from '../../_shared/helpers/mock-loader';

const paymentMock = loadMockConfig('.e2e-tests/order-flow/fixtures/mocks/payment-gateway.mock.yaml');
const mockFetch = createMockFetch([paymentMock], { fallback: 'error' });

// 测试中使用 mockFetch 替代 fetch
const res = await mockFetch(`${BASE_URL}/v1/charges`, { method: 'POST', ... });
```

### 方式 2：Playwright 网络拦截（适合路径 C 探索执行）

Playwright 探索时通过 `page.route()` 拦截请求，按 mock YAML 配置返回预设响应。此方式由 test-runner 路径 C 自动处理。

### 方式 3：外部 Mock Server（适合复杂微服务集成测试）

准备方案（test-prep）中指定外部 mock server 地址和启动命令。此方式需人工或 CI 预配置，test-runner 仅做健康探测。

### 决策规则

| 场景 | 推荐方式 | 说明 |
|------|----------|------|
| 纯 API 脚本（Stage 6 沉淀） | mock helper | 零外部依赖，脚本内完成 |
| Playwright 探索（路径 C） | 网络拦截 | 利用 Playwright 内置能力 |
| 多服务联调 / CI 集成 | 外部 Mock Server | 需要独立进程提供 mock |
| mock 配置简单 / 仅 1-2 个端点 | 脚本内硬编码 | 不值得为 1 个端点加载整套 mock |

### mock-loader 首次创建时机

- 首次有脚本需要 mock 且 `_shared/helpers/mock-loader.ts` 不存在时，由 `test-automation-builder` 的 subagent 一并生成
- mock-loader 本身也登记到 `asset-catalog.md` 的共享 helper 区块

---

## Mock 使用时机

### 在剧本中声明

剧本 frontmatter 的 `dependencies` 字段指定哪些服务需要 Mock：

```yaml
dependencies:
  - service: payment-gateway
    strategy: mock
    mock_config: fixtures/mocks/payment-gateway.mock.yaml
```

### 在执行前加载

`test-runner` 在执行前检查剧本的 dependencies：
1. 读取 mock_config 文件
2. 根据执行路径决定加载方式（helper / 网络拦截 / 外部 server）
3. 确认 Mock 服务就绪后再开始执行

### 在报告中记录

测试报告的"基本信息"中标注使用了哪些 Mock：

```markdown
| Mock 服务 | 配置文件 | 加载方式 |
|-----------|---------|----------|
| payment-gateway | fixtures/mocks/payment-gateway.mock.yaml | mock-helper |
```
