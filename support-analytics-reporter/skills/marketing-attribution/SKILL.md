---
name: marketing-attribution
description: 营销归因分析——多触点归因模型、渠道 ROI 计算和优化建议
argument-hint: "<营销渠道或归因需求描述>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(mkdir*)", "AskUserQuestion"]
---

# Marketing Attribution — 营销归因分析

定义归因模型、编写多触点归因 SQL、计算各渠道 ROI 并输出优化建议。

## 加载引用

Read skills/marketing-attribution/references/marketing-attribution-principles.md
Read skills/marketing-attribution/references/attribution-sql-patterns.md

## 强制执行规则

- 所有用户交互使用中文
- 至少实现两种归因模型进行交叉验证
- ROI 计算必须包含完整的成本和收入口径说明
- SQL 必须处理多触点去重和时间窗口截断
- 使用 AskUserQuestion 工具与用户交互

## 前置条件

- 已确认用户触点数据表结构（用户ID、触点渠道、触点时间、触点类型）
- 已确认转化事件定义（注册、下单、付款等）
- 已确认各渠道营销成本数据可用性

## Step 1: 定义归因模型

根据业务场景选择适合的归因模型：

| 模型 | 分配逻辑 | 适用场景 |
|------|---------|---------|
| 首次触点（First Touch） | 100% 归因给第一个触点 | 评估获客渠道效果 |
| 末次触点（Last Touch） | 100% 归因给最后一个触点 | 评估转化临门一脚 |
| 线性归因（Linear） | 平均分配给所有触点 | 重视完整路径 |
| U 型归因（Position-Based） | 首末各 40%，中间平分 20% | 兼顾获客和转化 |
| 时间衰减（Time Decay） | 越近的触点权重越高 | 强调近期营销效果 |

使用 AskUserQuestion 确认：
- "请确认以下归因分析参数：
  - 转化事件定义：{事件类型}
  - 归因时间窗口：转化前 30 天（是否调整？）
  - 优先实现哪些归因模型？（建议至少选择两种进行对比）
  - 是否有特定渠道需要重点关注？"

## Step 2: 编写多触点归因 SQL

### 数据准备 — 构建转化路径

```sql
-- 构建用户转化路径：转化前 N 天内的所有触点
WITH conversions AS (
    SELECT
        user_id,
        id AS conversion_id,
        created_at AS conversion_time,
        amount AS conversion_value
    FROM orders
    WHERE status = 'completed'
        AND created_at BETWEEN @start_date AND @end_date
),

touchpoints AS (
    SELECT
        t.user_id,
        t.channel,
        t.touchpoint_time,
        c.conversion_id,
        c.conversion_time,
        c.conversion_value,
        ROW_NUMBER() OVER (
            PARTITION BY c.conversion_id
            ORDER BY t.touchpoint_time
        ) AS touch_order,
        COUNT(*) OVER (
            PARTITION BY c.conversion_id
        ) AS total_touches
    FROM marketing_touchpoints t
    JOIN conversions c
        ON t.user_id = c.user_id
        AND t.touchpoint_time < c.conversion_time
        AND t.touchpoint_time >= DATE_SUB(c.conversion_time, INTERVAL 30 DAY)
)

SELECT * FROM touchpoints ORDER BY conversion_id, touch_order;
```

使用 AskUserQuestion 确认：
- "转化路径数据已构建完成，触点数据量和路径长度分布是否合理？"

**⏸️ 等待用户确认后进入归因模型计算。**

### 首次触点归因

```sql
-- 首次触点归因：100% 收入归因给第一个触点
SELECT
    channel,
    COUNT(DISTINCT conversion_id) AS conversions,
    SUM(conversion_value) AS attributed_revenue
FROM touchpoints
WHERE touch_order = 1
GROUP BY channel
ORDER BY attributed_revenue DESC;
```

### 末次触点归因

```sql
-- 末次触点归因：100% 收入归因给最后一个触点
SELECT
    channel,
    COUNT(DISTINCT conversion_id) AS conversions,
    SUM(conversion_value) AS attributed_revenue
FROM touchpoints
WHERE touch_order = total_touches
GROUP BY channel
ORDER BY attributed_revenue DESC;
```

### 线性归因

```sql
-- 线性归因：收入平均分配给路径中每个触点
SELECT
    channel,
    COUNT(DISTINCT conversion_id) AS touch_conversions,
    ROUND(SUM(conversion_value / total_touches), 2) AS attributed_revenue
FROM touchpoints
GROUP BY channel
ORDER BY attributed_revenue DESC;
```

### U 型归因

```sql
-- U 型归因：首末各 40%，中间触点平分 20%
SELECT
    channel,
    COUNT(DISTINCT conversion_id) AS touch_conversions,
    ROUND(SUM(
        CASE
            WHEN total_touches = 1 THEN conversion_value
            WHEN total_touches = 2 THEN conversion_value * 0.5
            WHEN touch_order = 1 THEN conversion_value * 0.4
            WHEN touch_order = total_touches THEN conversion_value * 0.4
            ELSE conversion_value * 0.2 / NULLIF(total_touches - 2, 0)
        END
    ), 2) AS attributed_revenue
FROM touchpoints
GROUP BY channel
ORDER BY attributed_revenue DESC;
```

### 时间衰减归因

```sql
-- 时间衰减归因：按距转化时间的远近分配权重
WITH decay_weights AS (
    SELECT
        *,
        -- 半衰期 7 天
        EXP(-0.693 * DATEDIFF(conversion_time, touchpoint_time) / 7) AS decay_weight
    FROM touchpoints
),

normalized AS (
    SELECT
        *,
        decay_weight / SUM(decay_weight) OVER (PARTITION BY conversion_id) AS normalized_weight
    FROM decay_weights
)

SELECT
    channel,
    COUNT(DISTINCT conversion_id) AS touch_conversions,
    ROUND(SUM(conversion_value * normalized_weight), 2) AS attributed_revenue
FROM normalized
GROUP BY channel
ORDER BY attributed_revenue DESC;
```

## Step 3: 计算各渠道 ROI

```sql
-- 各渠道 ROI 汇总（以线性归因为例，可替换为其他模型结果）
WITH channel_revenue AS (
    SELECT
        channel,
        ROUND(SUM(conversion_value / total_touches), 2) AS attributed_revenue,
        COUNT(DISTINCT conversion_id) AS attributed_conversions
    FROM touchpoints
    GROUP BY channel
),

channel_cost AS (
    SELECT
        channel,
        SUM(cost) AS total_cost
    FROM marketing_spend
    WHERE spend_date BETWEEN @start_date AND @end_date
    GROUP BY channel
)

SELECT
    r.channel,
    r.attributed_revenue,
    r.attributed_conversions,
    c.total_cost,
    -- ROI = (收入 - 成本) / 成本
    ROUND((r.attributed_revenue - c.total_cost) / NULLIF(c.total_cost, 0) * 100, 2) AS roi_pct,
    -- ROAS = 收入 / 成本
    ROUND(r.attributed_revenue / NULLIF(c.total_cost, 0), 2) AS roas,
    -- CPA = 成本 / 转化数
    ROUND(c.total_cost / NULLIF(r.attributed_conversions, 0), 2) AS cpa
FROM channel_revenue r
LEFT JOIN channel_cost c ON r.channel = c.channel
ORDER BY roi_pct DESC;
```

使用 AskUserQuestion 确认：
- "各渠道 ROI 分析结果如上，不同归因模型下渠道排名是否有显著差异？是否需要深入分析某个特定渠道？"

## Step 4: 归因模型对比与建议

生成归因模型对比分析：

1. **模型对比表** — 同一渠道在不同模型下的归因收入和排名差异
2. **关键发现** — 哪些渠道在不同模型下表现差异最大（可能被高估/低估）
3. **预算优化建议** — 基于归因结果的渠道预算调整方案
4. **下一步** — 建议进行增量测试验证的渠道

使用 AskUserQuestion 确认：
- "归因模型对比分析和预算优化建议已生成，是否需要调整或深入分析？"

**⏸️ 等待用户确认后进入 Step 5 输出产出物。**

## Step 5: 输出产出物

在 `attribution/` 目录下生成：

```
attribution/
├── attribution-report.md           # 归因分析完整报告
├── model-comparison.md             # 归因模型对比分析
├── sql/
│   ├── touchpoint-paths.sql        # 转化路径构建
│   ├── first-touch.sql             # 首次触点归因
│   ├── last-touch.sql              # 末次触点归因
│   ├── linear-attribution.sql      # 线性归因
│   ├── u-shaped-attribution.sql    # U 型归因
│   ├── time-decay-attribution.sql  # 时间衰减归因
│   └── channel-roi.sql             # 渠道 ROI 汇总
└── budget-optimization.md          # 预算优化建议
```

## 成功指标

- 至少实现两种归因模型并进行交叉验证
- SQL 查询可直接在目标数据库执行
- ROI 计算口径清晰，成本和收入定义明确
- 预算优化建议有数据支撑

## 失败指标

- 仅使用单一归因模型做结论
- SQL 未处理多触点去重或时间窗口截断
- ROI 计算遗漏关键成本项
- 建议缺乏数据支撑

## IMPORTANT

归因分析没有"正确答案"，只有"更合理的视角"。始终：
1. 用多个模型交叉验证，不依赖单一模型结论
2. 明确说明每个模型的假设和局限性
3. 建议通过增量测试（A/B Test）验证归因结论
4. 渠道预算调整建议必须渐进式，避免激进变动
