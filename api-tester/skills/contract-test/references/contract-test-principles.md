# 契约测试原则

## 1. 消费者驱动契约（CDC）

契约由消费方定义——只声明自己真正需要的字段和行为。

- 消费者写测试生成契约文件，描述"我需要什么"
- 提供者验证契约，保证"我能满足你的需要"
- 契约最小化——只包含消费者实际使用的字段
- 避免过度规约（over-specification）

### 工作流程

消费者编写测试 → 生成 Pact 契约 → 发布到 Broker（带版本+分支标签）→ 提供者 CI 验证 → 结果回传 → `can-i-deploy` → 安全部署

## 2. 契约分层策略

| 层级 | 验证内容 | 方法 |
|------|---------|------|
| Schema 层 | 字段类型、必填/可选、枚举范围 | JSON Schema / OpenAPI + Matcher |
| 语义层 | 状态码、错误格式统一性、分页/排序一致性 | HTTP 语义断言 |
| 行为层 | Provider State、状态转换、幂等性 | 状态驱动测试 |

## 3. 契约版本管理

- **标签策略**：环境名标签（main/staging/production）+ 分支名标签 + Pending/WIP Pacts
- **兼容性**：部署前 `can-i-deploy`；新增字段不破坏，删除必填字段须协商
- **演进**：加法式变更（Additive Change）优于破坏性变更

## 4. 多协议契约支持

| 协议 | 契约方式 | 工具 |
|------|---------|------|
| REST/HTTP | Pact HTTP 交互 | Pact、Dredd |
| GraphQL | 查询/变更请求-响应对 | Pact + GraphQL 插件 |
| gRPC | Proto 文件兼容性检查 | Buf、Pact 插件 |
| 异步消息 | 消息格式契约 | Pact Message、Spring Cloud Contract |
| WebSocket | 消息帧格式和事件序列 | 自定义 Schema 验证 |

## 5. 契约测试反模式

| 反模式 | 说明 |
|--------|------|
| 过度规约 | 断言消费者不使用的字段 |
| 功能测试化 | 把契约测试当集成测试——契约只验证接口形状 |
| 忽略 Provider State | 不设置前置状态导致验证失败 |
| 跳过 can-i-deploy | 不检查兼容性就部署 |
| 精确值匹配 | 用硬编码值而非 Matcher |
| 无 Broker | 契约散落各处，版本和状态无法追踪 |

## 6. 契约交互模板

每个契约交互必须包含：

- **交互名称**：[消费者] 向 [提供者] 请求 [操作]
- **Provider State**：[前置条件描述]
- **请求**：方法 + 路径 + Headers（Matcher）+ Body（结构化 Matcher）
- **响应**：状态码 + Headers（Matcher）+ Body（只断言消费者使用的字段，用 Matcher）
