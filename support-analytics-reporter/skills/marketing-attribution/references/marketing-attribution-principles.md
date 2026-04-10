# 营销归因分析原则与参考

## 归因模型对比

### 模型概览

| 模型 | 分配方式 | 优点 | 缺点 | 适用场景 |
|------|---------|------|------|---------|
| 首次触点 | 100% → 首次 | 简单直观，强调获客 | 忽视后续培育触点 | 品牌认知评估、获客渠道优化 |
| 末次触点 | 100% → 末次 | 简单，关注转化 | 忽视前期触点贡献 | 转化优化、短决策链产品 |
| 线性归因 | 均分所有触点 | 公平，考虑全路径 | 未区分触点重要性 | 路径短（≤5 个触点） |
| U 型归因 | 首末各 40%，中间 20% | 兼顾获客和转化 | 权重比例人为设定 | B2B 长决策链、高价值产品 |
| 时间衰减 | 近期触点权重更高 | 反映时效性 | 半衰期难以确定 | 限时促销、季节性产品 |
| 数据驱动 | 基于统计模型 | 最客观 | 需要大量数据 | 触点数据量大、有 ML 能力 |

### 如何选择归因模型

决策树：

```
你的业务决策链长度？
├── 短（1-2 触点）→ 首次或末次触点
├── 中（3-5 触点）→ 线性或 U 型
└── 长（5+ 触点）
    ├── 获客更重要？ → U 型（首次权重大）
    ├── 转化更重要？ → 时间衰减
    └── 有足够数据？ → 数据驱动
```

建议：**始终同时计算至少两种模型**，对比分析差异，差异大的渠道需要重点关注。

## 多触点归因 SQL 模式

### 转化路径构建核心模式

```sql
-- 核心模式：关联触点和转化事件
-- 关键点：
-- 1. 触点时间必须在转化时间之前
-- 2. 设置归因时间窗口（通常 7/14/30 天）
-- 3. 处理同一用户多次转化的情况

WITH conversion_paths AS (
    SELECT
        c.conversion_id,
        c.user_id,
        c.conversion_time,
        c.conversion_value,
        t.channel,
        t.touchpoint_time,
        -- 触点在路径中的位置
        ROW_NUMBER() OVER (
            PARTITION BY c.conversion_id
            ORDER BY t.touchpoint_time ASC
        ) AS position,
        -- 路径总触点数
        COUNT(*) OVER (
            PARTITION BY c.conversion_id
        ) AS path_length,
        -- 距转化的天数
        DATEDIFF(c.conversion_time, t.touchpoint_time) AS days_to_conversion
    FROM conversions c
    INNER JOIN touchpoints t
        ON c.user_id = t.user_id
        AND t.touchpoint_time >= DATE_SUB(c.conversion_time, INTERVAL @window_days DAY)
        AND t.touchpoint_time < c.conversion_time
)
```

### 去重规则

同一渠道在短时间内的多次触点需要去重：

```sql
-- 同一渠道在 1 小时内的触点只保留第一次
WITH deduped_touchpoints AS (
    SELECT *,
        LAG(touchpoint_time) OVER (
            PARTITION BY user_id, channel
            ORDER BY touchpoint_time
        ) AS prev_touch_time
    FROM marketing_touchpoints
)
SELECT *
FROM deduped_touchpoints
WHERE prev_touch_time IS NULL
    OR TIMESTAMPDIFF(HOUR, prev_touch_time, touchpoint_time) >= 1;
```

### 时间衰减权重计算

```sql
-- 半衰期模型：weight = 2^(-t/half_life)
-- half_life = 7 天时：
--   当天: 1.0, 7天前: 0.5, 14天前: 0.25, 21天前: 0.125

SET @half_life = 7;

SELECT
    *,
    POWER(2, -1.0 * days_to_conversion / @half_life) AS decay_weight,
    -- 归一化权重
    POWER(2, -1.0 * days_to_conversion / @half_life) /
        SUM(POWER(2, -1.0 * days_to_conversion / @half_life)) OVER (
            PARTITION BY conversion_id
        ) AS normalized_weight
FROM conversion_paths;
```

## ROI 计算公式

### 基础 ROI

```
ROI = (归因收入 - 渠道成本) / 渠道成本 × 100%
```

### ROAS（广告支出回报率）

```
ROAS = 归因收入 / 广告支出
```

ROAS > 1 表示广告支出有正回报。行业基准：
- 搜索广告: ROAS 3-5x
- 社交广告: ROAS 2-4x
- 展示广告: ROAS 1-2x
- 邮件营销: ROAS 5-10x

### CPA（单次获客成本）

```
CPA = 渠道总成本 / 归因转化数
```

### LTV:CAC 比率

```
LTV:CAC = 客户生命周期价值 / 获客成本
```

健康基准：LTV:CAC ≥ 3:1，回收期 ≤ 12 个月。

### 边际 ROI

```
边际 ROI = Δ收入 / Δ成本
```

当边际 ROI 下降到低于平均 ROI 时，该渠道接近饱和，应将预算转移到边际 ROI 更高的渠道。

## 增量测试方法

### 为什么需要增量测试

归因模型基于相关性，不能证明因果关系。增量测试通过对照实验验证渠道的真实贡献。

### A/B 测试设计

```
实验组（Treatment）: 看到广告的用户
对照组（Control）:    看不到广告的用户（PSA 或 holdout）

增量转化 = 实验组转化率 - 对照组转化率
增量 ROI = (增量转化 × 客单价 - 渠道成本) / 渠道成本
```

### 地理测试（Geo Test）

当无法随机分组时，使用地理区域作为实验单位：

1. 选择匹配的城市对（相似规模、消费水平）
2. 一组投放广告，一组不投放
3. 对比转化率差异
4. 控制季节性和趋势因素

### 增量测试优先级

优先测试以下场景：
1. **不同归因模型结论差异大的渠道** — 说明该渠道的真实贡献不确定
2. **预算占比高的渠道** — 验证高投入是否合理
3. **新渠道** — 历史数据少，归因不可靠
4. **品牌广告** — 通常在归因模型中被低估

## 常见陷阱

### 1. 末次点击偏见

大多数默认工具使用末次点击归因，导致：
- 搜索引擎被高估（用户搜索品牌词是在其他渠道影响后的行为）
- 展示广告和社交媒体被低估（它们的作用是激发兴趣，不是最终转化）

### 2. 跨设备归因缺失

用户在手机上看到广告，在电脑上完成购买。如果没有跨设备 ID 匹配，手机端的触点会丢失。

### 3. 线下触点遗漏

口碑推荐、线下活动等无法被数字触点追踪的渠道，在归因中完全缺失。

### 4. 相关性不等于因果

高频触点渠道（如重定向广告）在归因中容易获得高分，但这些用户本身就有高转化倾向——广告可能并未产生增量贡献。

### 5. 时间窗口选择偏差

- 窗口太短：遗漏长决策链前期触点
- 窗口太长：引入噪声，无关触点被错误归因
- 建议：根据业务决策链长度设定，B2C 通常 7-14 天，B2B 通常 30-90 天
