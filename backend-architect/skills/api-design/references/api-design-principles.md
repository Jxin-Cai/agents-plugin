# API 设计原则

本文档定义了 API 设计阶段必须遵循的原则。基于 RESTful 架构风格和行业最佳实践。

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

---

## 4. 版本控制

API 版本控制策略决定了系统的向后兼容性和演进能力。

### 策略对比

| 策略 | 示例 | 优点 | 缺点 |
|------|------|------|------|
| URL 路径 | `/api/v1/users` | 直观、易缓存、易路由 | URL 变更、客户端需改代码 |
| Header | `Accept-Version: v1` | URL 稳定 | 不够直观、调试困难 |
| 查询参数 | `/users?version=1` | 简单 | 缓存键复杂 |

**推荐**：URL 路径版本（`/api/v1/`），简单直观，团队认知成本低。

### 兼容性规则
- **向后兼容的变更**（不需要新版本）：新增可选字段、新增端点、新增枚举值
- **破坏性变更**（必须新版本）：删除字段、修改字段类型、修改必填/可选、修改语义
- 旧版本至少维护 **6-12 个月**，通过 Sunset Header 和文档提前通知下线

---

## 5. 分页策略

列表接口必须分页，无分页的列表接口是定时炸弹。

### 游标分页 vs 偏移分页

| 维度 | 偏移分页 | 游标分页 |
|------|---------|---------|
| 请求 | `?page=3&size=20` | `?cursor=eyJpZCI6MTAwfQ&size=20` |
| 优点 | 直观、可跳页 | 性能稳定、数据一致 |
| 缺点 | 大偏移量性能差、并发下数据漂移 | 不支持跳页 |
| 适用 | 管理后台、数据量小 | 无限滚动、数据量大、实时数据 |

**推荐**：对外 API 默认使用游标分页；管理后台内部 API 可用偏移分页。

### 分页响应格式
```json
{
  "data": [...],
  "pagination": {
    "next_cursor": "eyJpZCI6MTAwfQ",
    "has_more": true,
    "total_count": 1234
  }
}
```

---

## 6. 幂等性设计

网络不可靠，客户端可能重试。幂等性保证重复请求不会产生副作用。

### 天然幂等的方法
- **GET**：读取操作天然幂等
- **PUT**：全量替换天然幂等（同一请求执行多次结果相同）
- **DELETE**：删除已删除的资源返回 204 或 404 均可

### 需要额外保证的方法
- **POST（创建）**：使用 Idempotency-Key Header，服务端缓存请求结果
  ```
  POST /orders
  Idempotency-Key: client-generated-uuid
  ```
- **PATCH（部分更新）**：使用乐观锁（If-Match + ETag）防止并发冲突
  ```
  PATCH /orders/123
  If-Match: "etag-value"
  ```

### 幂等键设计
- 客户端生成 UUID 作为幂等键
- 服务端存储幂等键 → 响应映射（Redis，TTL 24 小时）
- 重复请求直接返回缓存的响应，不重新执行业务逻辑

---

## 7. 安全设计

API 安全不是可选项，是基础设施。

### 认证与授权
- **认证（Authentication）**：确认"你是谁"——JWT / OAuth 2.0 / API Key
- **授权（Authorization）**：确认"你能做什么"——RBAC / ABAC / 资源所有者检查
- Token 过期时间短（Access Token 15 分钟），配合 Refresh Token 续期
- API Key 用于服务间调用，JWT 用于用户会话

### 传输安全
- 强制 HTTPS，HTTP 请求 301 重定向到 HTTPS
- HSTS Header 防止降级攻击
- CORS 白名单控制跨域访问

### 输入防护
- 所有输入参数做白名单校验（类型、长度、格式、范围）
- 防 SQL 注入：使用参数化查询，绝不拼接 SQL
- 防 XSS：输出编码，Content-Type 明确设置
- 速率限制：按 IP / 用户 / API Key 分级限流
