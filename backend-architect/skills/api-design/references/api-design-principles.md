# API 设计原则——资源建模与请求响应

本文档定义了 API 资源建模、HTTP 语义和错误处理原则。横切关注点（版本控制、分页、幂等性、安全）见 `api-crosscutting-principles.md`。

---

## 1. 资源建模

API 的核心是资源（Resource），不是操作。资源是系统中可寻址的实体。

### 命名规范
- 使用 **复数名词** 作为资源路径：`/users`、`/orders`，不用 `/getUser`、`/createOrder`
- 使用 **连字符** 分隔多词资源：`/order-items`，不用驼峰或下划线
- 资源路径小写，最多 3 层嵌套：`/users/{id}/orders/{id}/items`
- 避免在 URL 中暴露实现细节（不用 `/api/v1/mysql/users`）

### 资源关系
- **一对多**：通过嵌套路径表达 `/users/{id}/orders`
- **多对多**：独立资源 + 关联端点 `/users/{id}/roles`（GET 查询）、`/user-roles`（管理关联）
- **子资源 vs 独立资源**：如果子实体脱离父实体没有意义，用嵌套路径；如果有独立生命周期，用独立资源

### 业务操作（非 CRUD）
- 状态变更：`POST /orders/{id}/actions/cancel`（动作作为子资源）
- 批量操作：`POST /orders/batch`（请求体包含操作列表）
- 搜索/过滤：`GET /orders?status=pending&created_after=2026-01-01`（查询参数）
- **绝不** 把业务操作设计成独立的 RPC 端点（如 `POST /cancelOrder`）

---

## 2. HTTP 语义正确性

每个 HTTP 方法有明确的语义约定，违反它会让 API 消费者困惑。

### 方法语义

| 方法 | 语义 | 幂等 | 安全 | 典型状态码 |
|------|------|------|------|-----------|
| GET | 读取资源，不产生副作用 | 是 | 是 | 200 |
| POST | 创建资源或触发操作 | 否 | 否 | 201（创建）/ 200（操作） |
| PUT | 全量替换资源 | 是 | 否 | 200 / 204 |
| PATCH | 部分更新资源 | 否* | 否 | 200 / 204 |
| DELETE | 删除资源 | 是 | 否 | 204 |

*PATCH 可以设计为幂等的（JSON Merge Patch），推荐这样做。

### 状态码使用

| 场景 | 状态码 | 说明 |
|------|--------|------|
| 创建成功 | 201 Created | 响应体包含创建的资源，Location Header 指向新资源 |
| 更新/删除成功无返回 | 204 No Content | 不返回响应体 |
| 客户端参数错误 | 400 Bad Request | 请求格式错误（JSON 语法错、缺必填字段） |
| 未认证 | 401 Unauthorized | Token 缺失或过期 |
| 无权限 | 403 Forbidden | 已认证但无权操作 |
| 资源不存在 | 404 Not Found | 资源 ID 不存在 |
| 资源冲突 | 409 Conflict | 并发更新冲突或唯一约束冲突 |
| 业务校验失败 | 422 Unprocessable Entity | 格式正确但业务规则不通过 |
| 限流 | 429 Too Many Requests | 附带 Retry-After Header |
| 服务器内部错误 | 500 Internal Server Error | 未预期的服务端异常 |

---

## 3. 错误处理

统一的错误响应是 API 可用性的基石。

### 统一错误格式
```json
{
  "error": {
    "code": "BUSINESS_ERROR_CODE",
    "message": "面向用户的错误描述（可国际化）",
    "details": [],
    "request_id": "req-uuid-for-tracing"
  }
}
```

### 错误码设计原则
- 使用 **大写蛇形命名**：`RESOURCE_NOT_FOUND`、`INSUFFICIENT_BALANCE`
- 按业务域分组：`ORDER_ALREADY_CANCELLED`、`PAYMENT_TIMEOUT`
- 区分 **客户端可修复** 的错误（参数错误、权限不足）和 **客户端不可修复** 的错误（服务端故障）
- 字段级校验错误放在 `details` 数组中，方便前端定位到具体表单字段

### 错误信息安全
- **绝不** 在错误响应中暴露堆栈信息、SQL 语句、内部服务地址
- 生产环境的 500 错误只返回通用消息 + request_id，用于日志关联排查
