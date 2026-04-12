---
name: monitoring-setup
description: 监控体系搭建 — Prometheus 配置、告警规则、Grafana 仪表盘
argument-hint: "<监控目标描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion"]
---

# 监控体系搭建

为目标系统设计并输出完整的监控体系，包含 Prometheus 采集配置、告警规则和 Grafana 仪表盘定义。

## 加载引用

Read file: `./references/monitoring-setup-principles.md`

## 强制执行规则

- 所有交互使用中文
- 输出的 YAML 配置必须可直接使用，语法正确
- 告警规则必须包含严重级别（critical / warning / info）
- 必须覆盖四大黄金信号（延迟、流量、错误率、饱和度）
- 每个告警必须配置通知渠道

## 前置条件

- 已明确目标系统的服务清单和技术栈
- 已明确监控目标（可用率、性能、安全）
- 已明确通知渠道（邮件、Slack、PagerDuty 等）

如信息不完整，使用 `AskUserQuestion` 补充。

## Step 1: 识别关键服务和指标

1. 梳理系统中所有需要监控的服务组件：
   - 应用服务（Web、API、Worker）
   - 数据库（MySQL、PostgreSQL、Redis、MongoDB）
   - 消息队列（RabbitMQ、Kafka）
   - 基础设施（主机、容器、网络）
2. 为每个组件定义关键指标：
   - 延迟：P50 / P95 / P99 响应时间
   - 流量：QPS、并发连接数
   - 错误率：5xx 比例、失败请求数
   - 饱和度：CPU / 内存 / 磁盘 / 网络利用率
3. 输出 `service-inventory.md`，列出所有监控目标及其指标

使用 `AskUserQuestion` 确认服务清单和指标是否完整。

## Step 2: 设计 Prometheus 监控配置

1. 设计 `prometheus.yml` 主配置：
   - `global` — scrape_interval、evaluation_interval
   - `scrape_configs` — 每个目标服务的采集任务
   - `rule_files` — 告警规则文件路径
   - `alerting` — Alertmanager 集成
2. 设计各 Exporter 配置：
   - `node_exporter` — 主机指标
   - `mysqld_exporter` / `postgres_exporter` — 数据库指标
   - `redis_exporter` — Redis 指标
   - 应用自定义指标（`/metrics` 端点）
3. 输出完整的 `prometheus.yml`

## Step 3: 设计告警规则

1. 按严重级别分类设计告警：
   - **Critical**：立即处理（服务宕机、数据库连接失败、磁盘即将满）
   - **Warning**：需关注（CPU > 80%、内存 > 85%、慢查询增加）
   - **Info**：信息记录（部署变更、配置更新）
2. 每条规则包含：
   - `alert` — 告警名称
   - `expr` — PromQL 表达式
   - `for` — 持续时间阈值
   - `labels.severity` — 严重级别
   - `annotations` — 摘要和描述
3. 设计 Alertmanager 路由和通知模板
4. 输出 `alert-rules.yml` 和 `alertmanager.yml`

使用 `AskUserQuestion` 确认告警阈值和通知渠道。

## Step 4: Grafana 仪表盘设计

1. 设计概览仪表盘（Overview Dashboard）：
   - 系统整体健康状态
   - 关键 SLI/SLO 指标
   - 活跃告警数量
2. 设计服务专属仪表盘：
   - 每个关键服务一个仪表盘
   - 包含该服务的四大黄金信号面板
3. 设计基础设施仪表盘：
   - 主机资源使用（CPU、内存、磁盘、网络）
   - 容器资源使用（如使用 Docker/K8s）
4. 输出 Grafana 仪表盘 JSON 配置

## Step 5: 输出监控配置文件

将所有配置文件整理输出至 `monitoring/` 目录：

```
monitoring/
├── service-inventory.md
├── prometheus.yml
├── alert-rules.yml
├── alertmanager.yml
└── grafana/
    ├── overview-dashboard.json
    └── {service}-dashboard.json
```

## 成功指标

- [ ] 所有关键服务均有对应的 scrape 配置
- [ ] 告警规则覆盖四大黄金信号
- [ ] 每条 critical 告警有明确的通知渠道
- [ ] Grafana 仪表盘可直接导入使用
- [ ] YAML 配置通过语法校验

## 失败指标

- 关键服务缺少监控覆盖
- 告警阈值不合理（过高导致漏报或过低导致告警风暴）
- 缺少 Alertmanager 通知配置
- 仪表盘缺少关键指标面板

<IMPORTANT>
Prometheus 采集间隔建议 15s，评估间隔建议 15s。
告警持续时间（for）不能设置为 0，至少 1m 以避免误告警。
所有 PromQL 表达式必须经过语法验证。
敏感信息（Webhook URL、邮箱密码）使用环境变量引用。
</IMPORTANT>
