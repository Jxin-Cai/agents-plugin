# Executive Dashboard 设计原则与参考

## KPI 层级设计方法

### 北极星指标（North Star Metric）

北极星指标是衡量产品/业务核心价值的单一指标，满足：
- **反映用户价值** — 用户获得的核心价值越多，指标越好
- **可衡量业务进展** — 指标增长直接关联业务增长
- **具有先导性** — 能预测未来收入/增长

常见北极星指标：
| 业务类型 | 北极星指标 | 说明 |
|----------|-----------|------|
| SaaS | MRR / ARR | 月度/年度经常性收入 |
| 电商 | GMV / 月订单数 | 交易规模 |
| 社交 | DAU / MAU | 活跃用户数 |
| 内容 | 总阅读时长 | 用户投入度 |
| 游戏 | ARPU / DAU | 用户价值 × 规模 |

### 一级指标（Key Drivers）

直接驱动北极星指标的核心因素，通常 3-5 个：

```
北极星: MRR
├── 新增 MRR（新客户）
├── 扩展 MRR（现有客户升级）
├── 流失 MRR（客户取消/降级）
└── 净留存率（NRR）
```

### 二级指标（Diagnostic Metrics）

每个一级指标下 2-3 个诊断指标：

```
新增 MRR
├── 销售漏斗转化率
├── 平均客单价
└── 获客渠道占比

流失 MRR
├── 各群体流失率
├── 流失原因分布
└── 预流失预警数
```

## SQL 模式模板

### 月度核心指标 CTE

```sql
-- 月度核心指标汇总
-- 数据库: MySQL 8.0+
-- 参数: @start_date, @end_date

WITH date_range AS (
    SELECT
        DATE_FORMAT(@start_date, '%Y-%m-01') AS period_start,
        LAST_DAY(@end_date) AS period_end
),

-- 收入指标
revenue_metrics AS (
    SELECT
        DATE_FORMAT(o.created_at, '%Y-%m') AS month,
        COUNT(DISTINCT o.id) AS total_orders,
        COUNT(DISTINCT o.user_id) AS paying_users,
        SUM(o.amount) AS total_revenue,
        AVG(o.amount) AS avg_order_value
    FROM orders o
    CROSS JOIN date_range d
    WHERE o.created_at BETWEEN d.period_start AND d.period_end
        AND o.status = 'completed'
    GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
),

-- 用户指标
user_metrics AS (
    SELECT
        DATE_FORMAT(u.created_at, '%Y-%m') AS month,
        COUNT(*) AS new_users
    FROM users u
    CROSS JOIN date_range d
    WHERE u.created_at BETWEEN d.period_start AND d.period_end
    GROUP BY DATE_FORMAT(u.created_at, '%Y-%m')
),

-- 活跃用户
active_users AS (
    SELECT
        DATE_FORMAT(e.event_time, '%Y-%m') AS month,
        COUNT(DISTINCT e.user_id) AS mau
    FROM user_events e
    CROSS JOIN date_range d
    WHERE e.event_time BETWEEN d.period_start AND d.period_end
    GROUP BY DATE_FORMAT(e.event_time, '%Y-%m')
)

SELECT
    r.month,
    r.total_revenue,
    r.total_orders,
    r.paying_users,
    r.avg_order_value,
    u.new_users,
    a.mau,
    -- 付费转化率
    ROUND(r.paying_users / NULLIF(a.mau, 0) * 100, 2) AS conversion_rate
FROM revenue_metrics r
LEFT JOIN user_metrics u ON r.month = u.month
LEFT JOIN active_users a ON r.month = a.month
ORDER BY r.month;
```

### 增长率计算（同比 + 环比）

```sql
-- 增长率计算：MoM（环比）和 YoY（同比）
WITH monthly_data AS (
    SELECT
        DATE_FORMAT(created_at, '%Y-%m') AS month,
        SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)

SELECT
    m.month,
    m.revenue AS current_revenue,

    -- 环比（Month over Month）
    prev.revenue AS prev_month_revenue,
    ROUND((m.revenue - prev.revenue) / NULLIF(prev.revenue, 0) * 100, 2) AS mom_growth_pct,

    -- 同比（Year over Year）
    yoy.revenue AS prev_year_revenue,
    ROUND((m.revenue - yoy.revenue) / NULLIF(yoy.revenue, 0) * 100, 2) AS yoy_growth_pct

FROM monthly_data m
LEFT JOIN monthly_data prev
    ON prev.month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(m.month, '-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
LEFT JOIN monthly_data yoy
    ON yoy.month = DATE_FORMAT(DATE_SUB(STR_TO_DATE(CONCAT(m.month, '-01'), '%Y-%m-%d'), INTERVAL 12 MONTH), '%Y-%m')
ORDER BY m.month;
```

### 异常检测

```sql
-- 基于均值 ± 2σ 的异常检测
WITH daily_revenue AS (
    SELECT
        DATE(created_at) AS dt,
        SUM(amount) AS revenue
    FROM orders
    WHERE status = 'completed'
        AND created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY DATE(created_at)
),

stats AS (
    SELECT
        AVG(revenue) AS mean_revenue,
        STDDEV(revenue) AS std_revenue
    FROM daily_revenue
)

SELECT
    d.dt,
    d.revenue,
    s.mean_revenue,
    ROUND(s.mean_revenue - 2 * s.std_revenue, 2) AS lower_bound,
    ROUND(s.mean_revenue + 2 * s.std_revenue, 2) AS upper_bound,
    CASE
        WHEN d.revenue > s.mean_revenue + 2 * s.std_revenue THEN '异常偏高'
        WHEN d.revenue < s.mean_revenue - 2 * s.std_revenue THEN '异常偏低'
        ELSE '正常'
    END AS anomaly_flag
FROM daily_revenue d
CROSS JOIN stats s
ORDER BY d.dt;
```

## 仪表盘设计原则

### 信息密度

- **5 秒规则** — 用户应在 5 秒内抓住核心信息
- **渐进披露** — 概览 → 趋势 → 明细，逐层深入
- **数据墨水比** — 最大化数据承载信息量，最小化装饰元素

### 钻取能力

设计三层钻取路径：
1. **L1 概览** — 核心指标卡片，红绿灯状态
2. **L2 趋势** — 点击卡片进入趋势图，支持时间范围切换
3. **L3 明细** — 点击趋势中的数据点进入明细表

### 实时性分层

| 指标类型 | 更新频率 | 实现方式 |
|----------|---------|---------|
| 营收/GMV | 准实时（5min） | 流处理 + 缓存 |
| 用户增长 | 每小时 | 定时任务 |
| 留存/LTV | 每日 | 离线批处理 |
| 预测指标 | 每周 | 模型定时运行 |

## 常用 SQL 模板

### 收入分析

```sql
-- 收入构成分析（按产品线/渠道）
SELECT
    product_line,
    SUM(amount) AS revenue,
    ROUND(SUM(amount) / SUM(SUM(amount)) OVER() * 100, 2) AS revenue_pct,
    COUNT(DISTINCT user_id) AS paying_users
FROM orders
WHERE status = 'completed'
    AND created_at BETWEEN @start_date AND @end_date
GROUP BY product_line
ORDER BY revenue DESC;
```

### 用户留存

```sql
-- 按月留存率矩阵（Cohort Retention）
WITH cohort AS (
    SELECT
        user_id,
        DATE_FORMAT(MIN(created_at), '%Y-%m') AS cohort_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY user_id
),

activity AS (
    SELECT
        o.user_id,
        c.cohort_month,
        TIMESTAMPDIFF(MONTH,
            STR_TO_DATE(CONCAT(c.cohort_month, '-01'), '%Y-%m-%d'),
            DATE_FORMAT(o.created_at, '%Y-%m-01')
        ) AS months_since
    FROM orders o
    JOIN cohort c ON o.user_id = c.user_id
    WHERE o.status = 'completed'
)

SELECT
    cohort_month,
    COUNT(DISTINCT CASE WHEN months_since = 0 THEN user_id END) AS m0,
    COUNT(DISTINCT CASE WHEN months_since = 1 THEN user_id END) AS m1,
    COUNT(DISTINCT CASE WHEN months_since = 2 THEN user_id END) AS m2,
    COUNT(DISTINCT CASE WHEN months_since = 3 THEN user_id END) AS m3,
    COUNT(DISTINCT CASE WHEN months_since = 6 THEN user_id END) AS m6,
    COUNT(DISTINCT CASE WHEN months_since = 12 THEN user_id END) AS m12
FROM activity
GROUP BY cohort_month
ORDER BY cohort_month;
```

### 运营效率

```sql
-- 获客成本（CAC）和生命周期价值（LTV）
WITH user_ltv AS (
    SELECT
        u.id AS user_id,
        u.source AS acquisition_channel,
        SUM(o.amount) AS lifetime_revenue,
        COUNT(o.id) AS total_orders,
        DATEDIFF(MAX(o.created_at), MIN(o.created_at)) AS active_days
    FROM users u
    LEFT JOIN orders o ON u.id = o.user_id AND o.status = 'completed'
    GROUP BY u.id, u.source
),

channel_cost AS (
    SELECT
        channel,
        SUM(cost) AS total_cost,
        COUNT(DISTINCT user_id) AS acquired_users
    FROM marketing_spend
    WHERE spend_date BETWEEN @start_date AND @end_date
    GROUP BY channel
)

SELECT
    c.channel,
    c.total_cost,
    c.acquired_users,
    ROUND(c.total_cost / NULLIF(c.acquired_users, 0), 2) AS cac,
    ROUND(AVG(l.lifetime_revenue), 2) AS avg_ltv,
    ROUND(AVG(l.lifetime_revenue) / NULLIF(c.total_cost / NULLIF(c.acquired_users, 0), 0), 2) AS ltv_cac_ratio
FROM channel_cost c
LEFT JOIN user_ltv l ON l.acquisition_channel = c.channel
GROUP BY c.channel, c.total_cost, c.acquired_users
ORDER BY ltv_cac_ratio DESC;
```
