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
2. 根据实际 Mock 工具（如 WireMock、MSW）加载配置
3. 确认 Mock 服务就绪后再开始执行

### 在报告中记录

测试报告的"基本信息"中标注使用了哪些 Mock：

```markdown
| Mock 服务 | 配置文件 |
|-----------|---------|
| payment-gateway | fixtures/mocks/payment-gateway.mock.yaml |
```
