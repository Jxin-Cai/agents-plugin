# 契约测试原则

本文档定义了契约测试阶段必须遵循的原则。

---

## 1. 消费者驱动契约（Consumer-Driven Contracts）

契约由消费方定义——只声明自己真正需要的字段和行为，而非提供方的完整 API 规格。

### 核心理念
- 消费者写测试生成契约文件，描述"我需要什么"
- 提供者验证契约，保证"我能满足你的需要"
- 契约是最小化的——只包含消费者实际使用的字段
- 避免过度规约（over-specification），不断言不使用的字段

### 工作流程
```
消费者编写测试 → 生成 Pact 契约文件
        ↓
契约发布到 Pact Broker（带版本号 + 分支标签）
        ↓
提供者 CI 验证契约
        ↓
验证结果回传 Broker
        ↓
`can-i-deploy` 部署前检查
        ↓
安全部署
```

---

## 2. 契约分层策略

### Schema 层契约
- 响应结构是否符合 JSON Schema / OpenAPI 规格
- 字段类型、必填/可选、枚举值范围
- 使用 Matcher（如 `Matchers.like()`）而非精确值匹配，保持灵活性

### 语义层契约
- HTTP 状态码是否符合预期（200/201/400/401/404/500）
- 错误响应格式是否统一（error code + message + details）
- 分页、排序、过滤参数的行为一致性

### 行为层契约
- Provider State 设置：描述前置状态（如"存在 ID 为 123 的用户"）
- 状态转换：操作前后的数据状态变化
- 幂等性保证：PUT/DELETE 重复调用的行为

---

## 3. 契约版本管理

### 标签策略
- 用环境名标签（main、staging、production）标记契约
- 用分支名标签标记开发中的契约
- 使用 Pending Pacts 防止新消费者契约破坏提供者构建
- 使用 WIP Pacts 自动验证未验证的契约

### 兼容性检查
- 部署前执行 `can-i-deploy` 检查兼容性
- 向后兼容规则：新增字段不破坏，删除必填字段必须协商
- Schema 演进策略：加法式变更（Additive Change）优于破坏性变更

---

## 4. 多协议契约支持

| 协议 | 契约方式 | 工具 |
|------|---------|------|
| REST/HTTP | Pact HTTP 交互 | Pact、Dredd |
| GraphQL | 查询/变更的请求-响应对 | Pact + GraphQL 插件 |
| gRPC | Proto 文件兼容性检查 | Buf、Pact 插件 |
| 异步消息 | 消息格式契约（Kafka/RabbitMQ） | Pact Message、Spring Cloud Contract |
| WebSocket | 消息帧格式和事件序列 | 自定义 Schema 验证 |

---

## 5. 契约测试反模式

### 必须避免的错误
- **过度规约**：断言提供方返回的每一个字段——消费者不用的字段不要断言
- **功能测试化**：把契约测试当集成测试写——契约测试只验证"接口形状"，不验证业务逻辑
- **忽略 Provider State**：不设置前置状态导致验证失败
- **跳过 can-i-deploy**：不检查兼容性就部署，失去契约测试的核心价值
- **精确值匹配**：用硬编码值而非 Matcher，导致测试脆弱
- **无 Broker 管理**：契约文件散落各处，版本和验证状态无法追踪

---

## 6. 契约测试用例设计模板

每个契约交互必须包含：

```
交互名称：[消费者] 向 [提供者] 请求 [操作]
Provider State：[前置条件描述]
请求：
  - 方法：GET/POST/PUT/DELETE
  - 路径：/api/v1/resource
  - Headers：Content-Type, Authorization（使用 Matcher）
  - Body：（如有，使用结构化 Matcher）
响应：
  - 状态码：200/201/400/404
  - Headers：Content-Type（使用 Matcher）
  - Body：（只断言消费者使用的字段，用 Matcher）
```
