# 监控体系搭建 — 参考原则

## Prometheus 配置要点

| 参数 | 建议值 | 说明 |
|------|--------|------|
| scrape_interval | 15s | 高频场景可降至 5s |
| scrape_timeout | 10s | 不超过 scrape_interval |
| evaluation_interval | 15s | 与 scrape_interval 一致 |
| 本地存储保留 | 15d | 长期用 Thanos / Cortex |

服务发现：小规模用 static_configs；K8s 用 kubernetes_sd_configs；AWS 用 ec2_sd_configs

优化手段：`relabel_configs` 统一标签、`metric_relabel_configs` 过滤无用指标

## 告警设计规范

### 严重级别与持续时间

| 级别 | 持续时间 | 响应要求 | 典型场景 |
|------|---------|---------|---------|
| critical | 1m-3m | < 15 分钟 | 服务宕机、DB 连接失败、磁盘满 |
| warning | 5m-10m | < 1 小时 | CPU>80%、内存>85%、慢查询增加 |
| info | 15m-30m | 趋势观察 | 部署变更、配置更新 |

### Alertmanager 分组配置

`group_by: [alertname, cluster, service]`、`group_wait: 30s`、`group_interval: 5m`、`repeat_interval: 4h`

## 四大黄金信号 PromQL

### 延迟（Latency）
```promql
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service))
```

### 流量（Traffic）
```promql
sum(rate(http_requests_total[5m])) by (service)
```

### 错误率（Errors）
```promql
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
/ sum(rate(http_requests_total[5m])) by (service)
```

### 饱和度（Saturation）
```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100
```

## 常用告警规则速查

| 告警名称 | 表达式核心 | 级别 | for |
|---------|-----------|------|-----|
| HostHighCpuUsage | CPU idle < 20% | warning | 5m |
| HostHighMemoryUsage | MemAvailable/Total < 15% | warning | 5m |
| HostDiskSpaceLow | avail/size < 10% | critical | 5m |
| ServiceHighErrorRate | 5xx rate > 5% | critical | 3m |
| ServiceHighLatency | P99 > 1s | warning | 5m |
| MySQLConnectionsHigh | connected/max > 80% | warning | 5m |
| MySQLSlowQueries | slow_queries rate > 0.1/s | warning | 5m |

## Grafana 仪表盘设计

### 布局规范
- 顶部行：关键 SLI 单值面板（Stat），一目了然
- 第二行：时间序列趋势图（24h）
- 下方行：按服务/实例维度分解
- 使用 Variables 实现环境/服务/实例筛选

### 面板类型选择

| 指标类型 | 推荐面板 |
|---------|---------|
| 当前值（可用率、错误率） | Stat / Gauge |
| 时间趋势（QPS、延迟） | Time Series |
| 分布（延迟分布） | Heatmap |
| 状态（服务健康） | State Timeline |
| 资源使用（CPU、内存） | Time Series + 阈值线 |

颜色规范：绿色=正常（< 阈值）、黄色=警告（接近阈值）、红色=严重（超过阈值）
