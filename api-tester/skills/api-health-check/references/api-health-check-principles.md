# API 健康检查原则

## 1. 健康检查端点设计

### 分级端点

| 级别 | 端点 | 消费者 | 内容 |
|------|------|--------|------|
| Liveness | `/health/live` | K8s Liveness Probe | 进程存活——不检查依赖 |
| Readiness | `/health/ready` | K8s Readiness / 负载均衡 | 能否接受流量——检查核心依赖 |
| Startup | `/health/startup` | K8s Startup Probe | 初始化是否完成 |
| Detail | `/health/detail` | 运维/监控系统 | 所有依赖详细状态 |

### 响应格式

遵循 RFC Health Check Response（draft-inadarei-api-health-check）：

- status: pass / warn / fail（对应 HTTP 200 / 200 / 503）
- version、releaseId、serviceId、description
- checks: 按依赖分组，每项含 componentType、status、time、output

## 2. 依赖健康检查

| 依赖类型 | 检查方式 | 超时 | 失败影响 |
|---------|---------|------|---------|
| 数据库 | 连接池状态 + `SELECT 1` | 3s | Readiness=fail |
| 缓存 | PING + 读写测试 | 2s | 可降级运行 |
| 消息队列 | 连接状态 + 生产者确认 | 3s | Readiness=fail |
| 上游服务 | 调用其 `/health/live` | 5s | 视重要性决定 |
| 文件系统 | 读写权限检查 | 2s | 视功能依赖决定 |

### 检查策略

- **频率**：Liveness 10s / Readiness 5-10s / Detail 30s / 告警 1min
- **失败容忍**：连续 N 次失败才判定不健康（避免瞬时抖动）
- **超时**：超时等同失败，不阻塞其他检查
- **并行**：所有依赖并行检查，总时间 <= 最慢单项
- **熔断**：长时间不健康时跳过检查直接 fail

## 3. SLI/SLO

### 关键 SLI

| SLI | 计算方式 | 典型值 |
|-----|---------|--------|
| 可用性 | 成功请求 / 总请求 | 99.9% |
| 延迟 P50/P95/P99 | 百分位响应时间 | 100ms / 500ms / 1s |
| 错误率 | 5xx / 总请求 | <0.1% |
| 饱和度 | CPU/内存/连接池 | <80% |

### SLO 原则

- 与业务价值挂钩——不是越高越好，99.999% 成本远高于 99.9%
- 用 Error Budget 管理：SLO 99.9% = 每月 43 分钟不可用
- 分级：核心 vs 非核心接口可有不同 SLO
- 定期回顾：每月/每季度基于实际数据调整
