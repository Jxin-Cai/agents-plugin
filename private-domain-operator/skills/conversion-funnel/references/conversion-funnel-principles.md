# 转化漏斗原则

本文档定义了全链路转化设计必须遵循的原则和实战方法论。用这些原则检验转化方案的完整性和可落地性。

---

## 1. 全链路转化漏斗模型

### 漏斗五层模型

```
公域流量池（抖音/小红书/电商/线下/广告）
        │
        ▼ 加好友率: 3-15%
    私域好友池
        │
        ▼ 入群率: 50-70%
    社群用户池
        │
        ▼ 首购率: 15-25%
    首购客户池
        │
        ▼ 复购率: 20-40%
    忠实客户池
        │
        ▼ 裂变率: 3-8%
    裂变新用户 → 回到顶部
```

### 漏斗的核心逻辑

1. **每层都有泄漏** — 没有100%转化率的环节，关键是找到泄漏最大的一层集中优化
2. **信任逐层建立** — 每一层都在积累信任，不能跳层（不能刚加好友就推销高客单价产品）
3. **价值交换原则** — 每次要求用户行动（加好友/入群/购买），都需要提供对等的价值
4. **漏斗可逆** — 用户可以从低层回到高层（如复购客户沉睡后需要重新激活）

---

## 2. 各环节转化率基准

### 加好友转化率（公域→私域）

| 渠道 | 转化率基准 | 优秀线 | 关键提升点 |
|------|-----------|--------|-----------|
| 电商包裹卡 | 3-5% | 8-12% | 卡片设计+利益点突出+二维码大小 |
| 视频号直播 | 5-10% | 15-20% | 口播引导+限时福利+评论区引导 |
| 抖音直播 | 3-8% | 10-15% | 小风车+私信自动回复 |
| 短信召回 | 1-2% | 3-5% | 短信文案+落地页+短链可信度 |
| 门店推荐 | 15-25% | 30-40% | 店员话术+即时利益+扫码便捷 |
| 朋友圈广告 | 2-5% | 5-8% | 素材质量+定向精准+落地页 |
| 小红书引流 | 1-3% | 3-5% | 内容种草+评论区引导+私信 |
| 老带新裂变 | 10-20% | 25-35% | 激励力度+社交关系信任背书 |

### 社群转化率（好友→社群→购买）

| 环节 | 转化率基准 | 优秀线 |
|------|-----------|--------|
| 好友→入群 | 50-60% | 70-80% |
| 入群→7日活跃 | 25-35% | 40-50% |
| 活跃→参与活动 | 30-40% | 50-60% |
| 参与活动→购买 | 15-25% | 25-35% |
| 整体（好友→首购） | 5-10% | 12-18% |

### 复购和裂变转化率

| 环节 | 转化率基准 | 优秀线 |
|------|-----------|--------|
| 首购→30天复购 | 15-20% | 25-35% |
| 复购→会员 | 10-15% | 20-30% |
| 客户→推荐好友 | 3-5% | 8-12% |
| 被推荐人→加好友 | 20-30% | 35-50% |

---

## 3. 渠道 ROI 分析框架

### ROI 计算公式

```
渠道 ROI = (渠道带来的GMV - 渠道成本) / 渠道成本 × 100%

其中：
- 渠道成本 = 获客成本(CAC) × 获客人数 + 运营成本
- 渠道GMV = 渠道用户数 × 转化率 × 客单价 × (1 + 复购系数)
```

### 各渠道成本参考

| 渠道 | 单个好友获客成本(CAC) | 月运营成本 | 适合阶段 |
|------|---------------------|-----------|---------|
| 包裹卡 | 0.5-2元/人 | 设计+印刷成本 | 已有电商订单 |
| 直播引流 | 3-10元/人 | 主播+场地+设备 | 有直播能力 |
| 短信召回 | 5-15元/人 | 0.04-0.06元/条 | 有老客手机号 |
| 门店引流 | 1-5元/人 | 物料+店员激励 | 有线下门店 |
| 信息流广告 | 10-50元/人 | 广告投放费 | 需要快速起量 |
| 内容引流 | 5-20元/人 | 内容制作费 | 长期品牌建设 |
| 老带新 | 3-8元/人 | 激励成本 | 有忠实用户基础 |

### ROI 健康度判断

| ROI | 健康度 | 策略 |
|-----|--------|------|
| >300% | 优秀 | 加大投入，快速放量 |
| 100-300% | 健康 | 持续优化，稳定投入 |
| 50-100% | 及格 | 优化转化率和复购率 |
| 0-50% | 亏损 | 找到瓶颈环节重点优化 |
| <0% | 严重亏损 | 停投或彻底调整策略 |

### 注意事项

- 短期 ROI 可能为负（前 1-2 个月在建立信任），要看 90 天 LTV ROI
- 不同渠道的用户质量不同，低 CAC 不等于高 ROI（如信息流广告用户 LTV 通常低于老带新用户）
- 品牌效应和口碑效应难以量化，纯算 ROI 可能低估品牌渠道的价值

---

## 4. 核心 SQL 查询模板

### 渠道获客效率

```sql
-- 各渠道加好友数和成本
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

### 社群转化漏斗

```sql
-- 社群从入群到购买的转化漏斗
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
SELECT 
    community_name,
    total_members,
    active_7d,
    ROUND(active_7d * 100.0 / total_members, 2) AS active_rate_pct,
    activity_participants,
    ROUND(activity_participants * 100.0 / active_7d, 2) AS activity_participation_pct,
    purchasers,
    ROUND(purchasers * 100.0 / total_members, 2) AS overall_conversion_pct,
    ROUND(total_gmv, 2) AS total_gmv,
    ROUND(total_gmv / NULLIF(purchasers, 0), 2) AS avg_order_value
FROM funnel
ORDER BY total_gmv DESC;
```

### 用户 LTV 分析

```sql
-- 各渠道用户 LTV（按加好友后90天计算）
SELECT 
    channel_source,
    COUNT(DISTINCT u.user_id) AS user_count,
    ROUND(AVG(COALESCE(p.total_spend_90d, 0)), 2) AS avg_ltv_90d,
    ROUND(SUM(COALESCE(p.total_spend_90d, 0)), 2) AS total_ltv_90d,
    ROUND(AVG(COALESCE(p.order_count_90d, 0)), 2) AS avg_orders_90d,
    ROUND(SUM(COALESCE(p.total_spend_90d, 0)) / NULLIF(SUM(u.cac), 0), 2) 
        AS ltv_cac_ratio
FROM private_domain_users u
LEFT JOIN (
    SELECT 
        user_id,
        SUM(order_amount) AS total_spend_90d,
        COUNT(DISTINCT order_id) AS order_count_90d
    FROM orders
    WHERE order_date <= DATE_ADD(
        (SELECT add_friend_date FROM private_domain_users WHERE user_id = orders.user_id),
        INTERVAL 90 DAY
    )
    GROUP BY user_id
) p ON u.user_id = p.user_id
WHERE u.add_friend_date <= DATE_SUB(CURDATE(), INTERVAL 90 DAY)
GROUP BY channel_source
ORDER BY avg_ltv_90d DESC;
```

### 复购率和裂变系数

```sql
-- 月度复购率趋势
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT user_id) AS paying_users,
    COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN user_id END) AS repeat_buyers,
    ROUND(COUNT(DISTINCT CASE WHEN order_sequence > 1 THEN user_id END) * 100.0 
          / COUNT(DISTINCT user_id), 2) AS repeat_rate_pct,
    ROUND(AVG(order_amount), 2) AS avg_order_value,
    ROUND(SUM(order_amount), 2) AS total_gmv
FROM (
    SELECT 
        user_id,
        order_id,
        order_date,
        order_amount,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) AS order_sequence
    FROM orders
    WHERE order_source = 'private_domain'
) ranked
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;

-- 裂变系数（K-factor）
SELECT 
    DATE_FORMAT(referral_date, '%Y-%m') AS month,
    COUNT(DISTINCT referrer_id) AS referrers,
    COUNT(DISTINCT referee_id) AS new_referrals,
    ROUND(COUNT(DISTINCT referee_id) * 1.0 / NULLIF(COUNT(DISTINCT referrer_id), 0), 2) 
        AS k_factor,
    COUNT(DISTINCT CASE WHEN referee_purchased = 1 THEN referee_id END) 
        AS referral_conversions,
    ROUND(COUNT(DISTINCT CASE WHEN referee_purchased = 1 THEN referee_id END) * 100.0 
          / NULLIF(COUNT(DISTINCT referee_id), 0), 2) AS referral_conversion_rate_pct
FROM referral_records
GROUP BY DATE_FORMAT(referral_date, '%Y-%m')
ORDER BY month;
```

---

## 5. 私聊话术设计原则

### 底层原则

1. **像朋友不像销售** — 用日常聊天的语气，不用「亲」「您好尊贵的客户」
2. **先给价值再要行动** — 先帮用户解决问题/提供信息，再引导购买
3. **一次一个请求** — 每条消息只引导一个行动，不要又让入群又让购买又让转发
4. **留有余地** — 每次推荐后加一句「不感兴趣也没关系」，降低心理压力
5. **个性化** — 基于用户标签定制内容，不要群发感（即使是群发，也要插入个性化变量）

### 话术模板框架

**需求诊断话术**
```
开场: "Hi {昵称}，看到你对{产品/品类}感兴趣"
提问: "方便聊聊你的需求吗？比如你主要想解决什么问题？"
追问: "你之前用过类似的产品吗？感觉怎么样？"
共情: "明白了，很多人都有这个困扰"
```

**产品推荐话术**
```
衔接: "根据你的情况，我推荐{产品名}"
理由: "因为它{核心卖点}，特别适合{用户场景}"
证明: "之前{类似用户}用了之后反馈{效果}"
价格: "现在{优惠信息}，比平时划算很多"
行动: "要不要试一下？不满意随时退"
```

**异议处理话术库**

| 异议 | 回应策略 | 话术示例 |
|------|---------|---------|
| "太贵了" | 价值重塑+拆分单价 | "每天算下来不到X元，比{日常消费}还便宜" |
| "再看看" | 限时+风险兜底 | "没问题～不过这个活动价只到{时间}，先拍下也不亏，不满意可以退" |
| "不需要" | 尊重+留钩子 | "完全理解！之后有需要随时找我，我帮你留意合适的" |
| "XX家更好" | 差异化+不贬低 | "那个也不错，我们的优势在{差异点}，你可以对比看看哪个更合适" |
| "效果好吗" | 案例+承诺 | "给你看几个真实反馈[截图]，而且我们支持{保障政策}" |

### 禁止事项

- ❌ 不要用「亲」「亲亲」等淘宝客服用语
- ❌ 不要连续发超过3条消息不等回复
- ❌ 不要在用户明确拒绝后继续推销
- ❌ 不要承诺无法兑现的效果
- ❌ 不要贬低竞品
- ❌ 不要在22:00后发推销消息
- ❌ 不要发大段复制粘贴的模板感文字
