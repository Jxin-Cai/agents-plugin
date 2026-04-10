# Mock 高级策略

在微服务架构中，简单的请求-响应 Mock 不足以覆盖复杂场景。本文档定义三种进阶 Mock 策略。

仅在以下情况读取本文件：
- 需要确保 Mock 行为与真实服务契约一致（Contract Mock）
- 需要模拟下游服务异常（故障注入）
- Mock 调用有先后依赖关系（有状态 Mock）

---

## Contract Mock（契约 Mock）

基于服务契约（OpenAPI / Protobuf / GraphQL Schema）自动生成 Mock，确保 Mock 行为与真实服务契约一致。

```yaml
# 在 mock 配置中声明契约来源
contract:
  type: openapi | protobuf | graphql
  source: ./contracts/payment-gateway.openapi.yaml   # 契约文件路径
  auto_validate: true   # 请求/响应自动校验是否符合契约
```

当 `auto_validate: true` 时，Mock 会拒绝不符合契约的请求并报错，防止测试脚本与真实接口产生隐性偏离。

---

## 故障注入 Mock

模拟下游服务的异常行为，验证被测系统的容错能力：

```yaml
# 在 endpoints 中使用 fault_injection 字段
endpoints:
  - name: 支付网关超时
    path: /v1/charges
    method: POST
    fault_injection:
      type: timeout | error | slow | partial_failure
      timeout_ms: 30000        # timeout 类型：延迟时长
      error_rate: 0.5          # error 类型：50% 概率返回错误
      slow_min_ms: 2000        # slow 类型：随机延迟范围
      slow_max_ms: 5000
    response:                  # 故障触发时的响应
      status: 503
      body:
        error: "service_unavailable"
```

常见故障注入场景：`timeout`（超时）、`error`（随机错误）、`slow`（慢响应）、`partial_failure`（部分字段缺失或格式异常）。

---

## 有状态 Mock

某些服务调用有先后依赖（先创建再查询），无状态 Mock 无法覆盖。有状态 Mock 维护内存状态：

```yaml
stateful: true
state_store: memory    # 运行期间维护状态

endpoints:
  - name: 创建订单
    path: /v1/orders
    method: POST
    response:
      status: 201
      body:
        id: "{{ auto_id }}"
        status: "created"
    side_effect:
      store:             # 将数据存入状态
        key: "order_{{ response.body.id }}"
        value: "{{ response.body }}"

  - name: 查询订单
    path: /v1/orders/{id}
    method: GET
    response:
      from_store:        # 从状态中读取
        key: "order_{{ request.path.id }}"
      fallback:
        status: 404
        body:
          error: "order_not_found"
```
