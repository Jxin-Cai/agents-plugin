# 监控体系搭建 — 参考原则

## Prometheus 配置最佳实践

### 采集配置
- **scrape_interval**：建议 15s，兼顾精度和性能；高频场景可降至 5s
- **scrape_timeout**：不超过 scrape_interval，建议 10s
- **evaluation_interval**：与 scrape_interval 保持一致
- 使用 `relabel_configs` 统一标签命名
- 使用 `metric_relabel_configs` 过滤不需要的指标，降低存储压力

### 服务发现
- 静态配置适用于小规模环境
- Kubernetes 环境使用 `kubernetes_sd_configs`
- AWS 环境使用 `ec2_sd_configs`
- Consul 环境使用 `consul_sd_configs`

### 存储
- 本地存储保留 15 天，长期存储使用 Thanos 或 Cortex
- 使用 `--storage.tsdb.retention.time=15d` 控制保留时间
- 大规模部署考虑联邦架构（Federation）

## 告警规则设计方法

### 阈值设定
- 基于历史数据的 P95/P99 设定基线
- 预留 20% 余量作为告警阈值
- 区分静态阈值和动态阈值（基于时间窗口的偏差检测）

### 持续时间（for）
| 严重级别 | 建议持续时间 | 说明 |
|---------|-------------|------|
| critical | 1m - 3m | 紧急问题，快速响应 |
| warning | 5m - 10m | 需要关注，避免误报 |
| info | 15m - 30m | 信息记录，趋势观察 |

### 严重级别定义
- **critical**：影响用户、收入或数据安全，需立即响应（< 15 分钟）
- **warning**：可能升级为 critical，需在 1 小时内处理
- **info**：记录性告警，用于审计和趋势分析

### 告警抑制和分组
```yaml
# Alertmanager 分组示例
group_by: ['alertname', 'cluster', 'service']
group_wait: 30s
group_interval: 5m
repeat_interval: 4h
```

## 四大黄金信号

### 延迟（Latency）
```promql
# HTTP 请求延迟 P99
histogram_quantile(0.99,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)

# 慢请求比例（> 500ms）
sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m])) by (service)
/
sum(rate(http_request_duration_seconds_count[5m])) by (service)
```

### 流量（Traffic）
```promql
# QPS
sum(rate(http_requests_total[5m])) by (service)

# 并发连接数
sum(http_connections_current) by (service)
```

### 错误率（Errors）
```promql
# 5xx 错误率
sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
/
sum(rate(http_requests_total[5m])) by (service)

# 错误请求绝对数
sum(increase(http_requests_total{status=~"5.."}[1h])) by (service)
```

### 饱和度（Saturation）
```promql
# CPU 使用率
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100)

# 内存使用率
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# 磁盘使用率
(1 - node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100
```

## Grafana 仪表盘设计原则

### 布局规范
- 顶部行：关键 SLI 单值面板（Stat Panel），一目了然
- 第二行：时间序列趋势图，展示过去 24h 变化
- 下方行：详细指标分解（按服务、实例维度）
- 使用变量（Variables）实现环境/服务/实例筛选

### 面板类型选择
| 指标类型 | 推荐面板 |
|---------|---------|
| 当前值（可用率、错误率） | Stat / Gauge |
| 时间趋势（QPS、延迟） | Time Series |
| 分布（延迟分布） | Heatmap / Histogram |
| 状态（服务健康） | State Timeline |
| 资源使用（CPU、内存） | Time Series + 阈值线 |

### 颜色规范
- 绿色：正常（< 阈值）
- 黄色/橙色：警告（接近阈值）
- 红色：严重（超过阈值）

## 常用告警规则模板

### 主机级别
```yaml
groups:
  - name: host-alerts
    rules:
      - alert: HostHighCpuUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) by (instance) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "主机 CPU 使用率过高 ({{ $labels.instance }})"
          description: "CPU 使用率已达 {{ $value | printf \"%.1f\" }}%，超过 80% 阈值。"

      - alert: HostHighMemoryUsage
        expr: (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "主机内存使用率过高 ({{ $labels.instance }})"
          description: "内存使用率已达 {{ $value | printf \"%.1f\" }}%，超过 85% 阈值。"

      - alert: HostDiskSpaceLow
        expr: (1 - node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "主机磁盘空间不足 ({{ $labels.instance }})"
          description: "磁盘 {{ $labels.mountpoint }} 使用率已达 {{ $value | printf \"%.1f\" }}%。"
```

### 服务级别
```yaml
groups:
  - name: service-alerts
    rules:
      - alert: ServiceHighErrorRate
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
          /
          sum(rate(http_requests_total[5m])) by (service) > 0.05
        for: 3m
        labels:
          severity: critical
        annotations:
          summary: "服务错误率过高 ({{ $labels.service }})"
          description: "5xx 错误率已达 {{ $value | printf \"%.2f\" }}，超过 5% 阈值。"

      - alert: ServiceHighLatency
        expr: |
          histogram_quantile(0.99,
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
          ) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "服务 P99 延迟过高 ({{ $labels.service }})"
          description: "P99 延迟已达 {{ $value | printf \"%.2f\" }}s，超过 1s 阈值。"
```

### 数据库级别
```yaml
groups:
  - name: database-alerts
    rules:
      - alert: MySQLConnectionsHigh
        expr: mysql_global_status_threads_connected / mysql_global_variables_max_connections > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "MySQL 连接数接近上限"
          description: "当前连接使用率 {{ $value | printf \"%.1f\" }}%。"

      - alert: MySQLSlowQueries
        expr: rate(mysql_global_status_slow_queries[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "MySQL 慢查询增加"
          description: "慢查询速率 {{ $value | printf \"%.2f\" }}/s。"
```
