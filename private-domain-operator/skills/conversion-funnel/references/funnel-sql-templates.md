# 核心 SQL 查询模板

## 渠道获客效率

```sql
SELECT 
    channel_source,
    COUNT(DISTINCT user_id) AS new_friends,
    SUM(channel_cost) AS total_cost,
    ROUND(SUM(channel_cost) / COUNT(DISTINCT user_id), 2) AS cac,
    COUNT(DISTINCT CASE WHEN first_purchase_date IS NOT NULL 
          THEN user_id END) AS converted_users,
    ROUND(COUNT(DISTINCT CASE WHEN first_purchase_date IS NOT NULL 
          THEN user_id END) * 100.0 / COUNT(DISTINCT user_id), 2) 
          AS conversion_rate_pct
FROM private_domain_users
WHERE add_friend_date BETWEEN '{start_date}' AND '{end_date}'
GROUP BY channel_source
ORDER BY new_friends DESC;
```

## 社群转化漏斗

```sql
WITH funnel AS (
    SELECT
        community_name,
        COUNT(DISTINCT user_id) AS total_members,
        COUNT(DISTINCT CASE WHEN last_active_date >= DATE_SUB(CURDATE(), INTERVAL 7 DAY) 
              THEN user_id END) AS active_7d,
        COUNT(DISTINCT CASE WHEN participated_activity = 1 
              THEN user_id END) AS activity_participants,
        COUNT(DISTINCT CASE WHEN has_purchased = 1 
              THEN user_id END) AS purchasers,
        SUM(CASE WHEN has_purchased = 1 THEN total_gmv ELSE 0 END) AS total_gmv
    FROM community_members cm
    LEFT JOIN user_purchases up ON cm.user_id = up.user_id
    WHERE cm.join_date BETWEEN '{start_date}' AND '{end_date}'
    GROUP BY community_name
)
SELECT community_name, total_members, active_7d,
    ROUND(active_7d * 100.0 / total_members, 2) AS active_rate_pct,
    activity_participants,
    ROUND(activity_participants * 100.0 / active_7d, 2) AS activity_pct,
    purchasers,
    ROUND(purchasers * 100.0 / total_members, 2) AS conversion_pct,
    ROUND(total_gmv, 2) AS total_gmv,
    ROUND(total_gmv / NULLIF(purchasers, 0), 2) AS avg_order_value
FROM funnel ORDER BY total_gmv DESC;
```

## 用户 LTV 分析

```sql
SELECT 
    channel_source,
    COUNT(DISTINCT u.user_id) AS user_count,
    ROUND(AVG(COALESCE(p.total_spend_90d, 0)), 2) AS avg_ltv_90d,
    ROUND(SUM(COALESCE(p.total_spend_90d, 0)), 2) AS total_ltv_90d,
    ROUND(SUM(COALESCE(p.total_spend_90d, 0)) / NULLIF(SUM(u.cac), 0), 2) AS ltv_cac_ratio
FROM private_domain_users u
LEFT JOIN (
    SELECT user_id,
        SUM(order_amount) AS total_spend_90d,
        COUNT(DISTINCT order_id) AS order_count_90d
    FROM orders
    WHERE order_date <= DATE_ADD(
        (SELECT add_friend_date FROM private_domain_users WHERE user_id = orders.user_id),
        INTERVAL 90 DAY)
    GROUP BY user_id
) p ON u.user_id = p.user_id
WHERE u.add_friend_date <= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY channel_source ORDER BY avg_ltv_90d DESC;
```

## 复购率与裂变系数

```sql
-- 月度复购率趋势
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS paying_users,
    COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN user_id END) AS repeat_buyers,
    ROUND(COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN user_id END) * 100.0 
          / COUNT(DISTINCT user_id), 2) AS repeat_rate_pct,
    ROUND(AVG(order_amount), 2) AS avg_order_value,
    ROUND(SUM(order_amount), 2) AS total_gmv
FROM (SELECT user_id, order_id, order_date, order_amount,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) AS order_sequence
    FROM orders WHERE order_source = 'private_domain') ranked
GROUP BY DATE_FORMAT(order_date, '%Y-%m') ORDER BY month;

-- 裂变系数（K-factor）
SELECT DATE_FORMAT(referral_date, '%Y-%m') AS month,
    COUNT(DISTINCT referrer_id) AS referrers,
    COUNT(DISTINCT referee_id) AS new_referrals,
    ROUND(COUNT(DISTINCT referee_id) * 1.0 / NULLIF(COUNT(DISTINCT referrer_id), 0), 2) AS k_factor,
    COUNT(DISTINCT CASE WHEN referee_purchased = 1 THEN referee_id END) AS referral_conversions
FROM referral_records
GROUP BY DATE_FORMAT(referral_date, '%Y-%m') ORDER BY month;
```
