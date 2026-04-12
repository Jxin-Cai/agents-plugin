# 营销归因 SQL 模式参考

## 转化路径构建核心模式

```sql
-- 关联触点和转化事件（MySQL 8.0+）
-- 关键点：触点在转化前、设置归因窗口、处理多次转化
WITH conversion_paths AS (
    SELECT c.conversion_id, c.user_id, c.conversion_time, c.conversion_value,
           t.channel, t.touchpoint_time,
           ROW_NUMBER() OVER (PARTITION BY c.conversion_id ORDER BY t.touchpoint_time) AS position,
           COUNT(*) OVER (PARTITION BY c.conversion_id) AS path_length,
           DATEDIFF(c.conversion_time, t.touchpoint_time) AS days_to_conversion
    FROM conversions c
    INNER JOIN touchpoints t ON c.user_id = t.user_id
        AND t.touchpoint_time >= DATE_SUB(c.conversion_time, INTERVAL @window_days DAY)
        AND t.touchpoint_time < c.conversion_time
)
SELECT * FROM conversion_paths;
```

## 触点去重规则

```sql
-- 同一渠道 1 小时内仅保留首次触点
WITH deduped AS (
    SELECT *, LAG(touchpoint_time) OVER (
        PARTITION BY user_id, channel ORDER BY touchpoint_time
    ) AS prev_time
    FROM marketing_touchpoints
)
SELECT * FROM deduped
WHERE prev_time IS NULL OR TIMESTAMPDIFF(HOUR, prev_time, touchpoint_time) >= 1;
```

## 时间衰减权重

```sql
-- 半衰期 7 天：weight = 2^(-t/7)
-- 当天 1.0 → 7天前 0.5 → 14天前 0.25
SET @half_life = 7;
SELECT *,
    POWER(2, -1.0 * days_to_conversion / @half_life) AS decay_weight,
    POWER(2, -1.0 * days_to_conversion / @half_life) /
        SUM(POWER(2, -1.0 * days_to_conversion / @half_life))
        OVER (PARTITION BY conversion_id) AS normalized_weight
FROM conversion_paths;
```

## U 型归因权重

```sql
SELECT channel,
    ROUND(SUM(CASE
        WHEN path_length = 1 THEN conversion_value
        WHEN path_length = 2 THEN conversion_value * 0.5
        WHEN position = 1 THEN conversion_value * 0.4
        WHEN position = path_length THEN conversion_value * 0.4
        ELSE conversion_value * 0.2 / NULLIF(path_length - 2, 0)
    END), 2) AS attributed_revenue
FROM conversion_paths GROUP BY channel ORDER BY attributed_revenue DESC;
```

## 渠道 ROI 汇总

```sql
WITH channel_revenue AS (
    SELECT channel,
           ROUND(SUM(conversion_value / path_length), 2) AS attributed_revenue,
           COUNT(DISTINCT conversion_id) AS attributed_conversions
    FROM conversion_paths GROUP BY channel
),
channel_cost AS (
    SELECT channel, SUM(cost) AS total_cost
    FROM marketing_spend WHERE spend_date BETWEEN @start_date AND @end_date
    GROUP BY channel
)
SELECT r.channel, r.attributed_revenue, c.total_cost,
    ROUND((r.attributed_revenue - c.total_cost) / NULLIF(c.total_cost, 0) * 100, 2) AS roi_pct,
    ROUND(r.attributed_revenue / NULLIF(c.total_cost, 0), 2) AS roas,
    ROUND(c.total_cost / NULLIF(r.attributed_conversions, 0), 2) AS cpa
FROM channel_revenue r LEFT JOIN channel_cost c ON r.channel = c.channel
ORDER BY roi_pct DESC;
```
