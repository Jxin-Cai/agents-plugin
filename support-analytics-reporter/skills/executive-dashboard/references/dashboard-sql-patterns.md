# 高管仪表盘 SQL 模式参考

## 月度核心指标 CTE 模式

```sql
-- 月度核心指标汇总（MySQL 8.0+）
-- 参数: @start_date, @end_date
WITH revenue_metrics AS (
    SELECT DATE_FORMAT(created_at, '%Y-%m') AS month,
           COUNT(DISTINCT id) AS total_orders,
           COUNT(DISTINCT user_id) AS paying_users,
           SUM(amount) AS total_revenue,
           AVG(amount) AS avg_order_value
    FROM orders
    WHERE created_at BETWEEN @start_date AND @end_date AND status = 'completed'
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
),
user_metrics AS (
    SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, COUNT(*) AS new_users
    FROM users WHERE created_at BETWEEN @start_date AND @end_date
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
),
active_users AS (
    SELECT DATE_FORMAT(event_time, '%Y-%m') AS month, COUNT(DISTINCT user_id) AS mau
    FROM user_events WHERE event_time BETWEEN @start_date AND @end_date
    GROUP BY DATE_FORMAT(event_time, '%Y-%m')
)
SELECT r.month, r.total_revenue, r.total_orders, r.paying_users,
       r.avg_order_value, u.new_users, a.mau,
       ROUND(r.paying_users / NULLIF(a.mau, 0) * 100, 2) AS conversion_rate
FROM revenue_metrics r
LEFT JOIN user_metrics u ON r.month = u.month
LEFT JOIN active_users a ON r.month = a.month
ORDER BY r.month;
```

## 增长率（MoM + YoY）

```sql
WITH monthly_data AS (
    SELECT DATE_FORMAT(created_at, '%Y-%m') AS month, SUM(amount) AS revenue
    FROM orders WHERE status = 'completed'
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT m.month, m.revenue,
       ROUND((m.revenue - prev.revenue) / NULLIF(prev.revenue, 0) * 100, 2) AS mom_pct,
       ROUND((m.revenue - yoy.revenue) / NULLIF(yoy.revenue, 0) * 100, 2) AS yoy_pct
FROM monthly_data m
LEFT JOIN monthly_data prev ON prev.month = DATE_FORMAT(
    DATE_SUB(STR_TO_DATE(CONCAT(m.month,'-01'), '%Y-%m-%d'), INTERVAL 1 MONTH), '%Y-%m')
LEFT JOIN monthly_data yoy ON yoy.month = DATE_FORMAT(
    DATE_SUB(STR_TO_DATE(CONCAT(m.month,'-01'), '%Y-%m-%d'), INTERVAL 12 MONTH), '%Y-%m')
ORDER BY m.month;
```

## 异常检测（均值 +/- 2 sigma）

```sql
WITH daily_revenue AS (
    SELECT DATE(created_at) AS dt, SUM(amount) AS revenue
    FROM orders WHERE status = 'completed' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
    GROUP BY DATE(created_at)
),
stats AS (
    SELECT AVG(revenue) AS mu, STDDEV(revenue) AS sigma FROM daily_revenue
)
SELECT d.dt, d.revenue,
       CASE WHEN d.revenue > s.mu + 2*s.sigma THEN '异常偏高'
            WHEN d.revenue < s.mu - 2*s.sigma THEN '异常偏低'
            ELSE '正常' END AS anomaly_flag
FROM daily_revenue d CROSS JOIN stats s ORDER BY d.dt;
```

## Cohort 留存矩阵

```sql
WITH cohort AS (
    SELECT user_id, DATE_FORMAT(MIN(created_at), '%Y-%m') AS cohort_month
    FROM orders WHERE status = 'completed' GROUP BY user_id
),
activity AS (
    SELECT o.user_id, c.cohort_month,
           TIMESTAMPDIFF(MONTH, STR_TO_DATE(CONCAT(c.cohort_month,'-01'), '%Y-%m-%d'),
                         DATE_FORMAT(o.created_at, '%Y-%m-01')) AS months_since
    FROM orders o JOIN cohort c ON o.user_id = c.user_id WHERE o.status = 'completed'
)
SELECT cohort_month,
       COUNT(DISTINCT CASE WHEN months_since=0 THEN user_id END) AS m0,
       COUNT(DISTINCT CASE WHEN months_since=1 THEN user_id END) AS m1,
       COUNT(DISTINCT CASE WHEN months_since=3 THEN user_id END) AS m3,
       COUNT(DISTINCT CASE WHEN months_since=6 THEN user_id END) AS m6,
       COUNT(DISTINCT CASE WHEN months_since=12 THEN user_id END) AS m12
FROM activity GROUP BY cohort_month ORDER BY cohort_month;
```

## CAC 与 LTV 速查

CAC = 渠道总成本 / 归因获客数，LTV = AVG(用户累计消费)，LTV:CAC ≥ 3:1 为健康。
详细 SQL 参见 marketing-attribution 的 channel-roi 查询。
