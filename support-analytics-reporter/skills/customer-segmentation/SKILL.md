---
name: customer-segmentation
description: 客户分群分析——RFM 评分、聚类分群、群体画像和策略建议
argument-hint: "<客户数据或分群需求描述>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(mkdir*)", "AskUserQuestion"]
---

# Customer Segmentation — 客户分群分析

基于 RFM 模型和聚类算法进行客户分群，输出群体画像和针对性运营策略。

## 加载引用

使用 Read 工具加载：
- `references/customer-segmentation-principles.md`

## 强制执行规则

- 所有用户交互使用中文
- RFM 评分必须基于实际数据分布，不硬编码阈值
- 分群结果必须包含统计验证（群体间差异显著性检验）
- Python 代码必须包含完整的 import 和数据加载逻辑
- 使用 AskUserQuestion 工具与用户交互

## 前置条件

- 已确认交易数据表结构（用户ID、订单时间、金额）
- 数据时间范围至少覆盖 6 个月
- 已了解业务对"活跃"和"高价值"的定义

## Step 1: RFM 数据准备

计算每位客户的 RFM 三个维度原始值：

1. **Recency（最近一次消费距今天数）**
   ```sql
   SELECT
       user_id,
       DATEDIFF(CURDATE(), MAX(created_at)) AS recency_days
   FROM orders
   WHERE status = 'completed'
   GROUP BY user_id;
   ```

2. **Frequency（消费频次）**
   ```sql
   SELECT
       user_id,
       COUNT(DISTINCT id) AS frequency
   FROM orders
   WHERE status = 'completed'
       AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
   GROUP BY user_id;
   ```

3. **Monetary（消费总金额）**
   ```sql
   SELECT
       user_id,
       SUM(amount) AS monetary
   FROM orders
   WHERE status = 'completed'
       AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
   GROUP BY user_id;
   ```

使用 AskUserQuestion 确认：
- "请确认以下 RFM 计算参数：
  - 分析时间窗口：最近 12 个月（是否调整？）
  - 订单状态筛选：仅 completed（是否包含其他状态？）
  - 金额字段：amount（是否需要扣除退款？）"

## Step 2: RFM 评分与分群

使用 Python 基于分位数进行评分和分群：

```python
import pandas as pd
import numpy as np
from sqlalchemy import create_engine

# 数据加载
engine = create_engine("mysql+pymysql://user:pass@host:3306/db")
query = """
SELECT
    user_id,
    DATEDIFF(CURDATE(), MAX(created_at)) AS recency,
    COUNT(DISTINCT id) AS frequency,
    SUM(amount) AS monetary
FROM orders
WHERE status = 'completed'
    AND created_at >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
GROUP BY user_id
"""
df = pd.read_sql(query, engine)

# 基于分位数评分（1-5分，5为最佳）
df['r_score'] = pd.qcut(df['recency'], 5, labels=[5, 4, 3, 2, 1])  # 越小越好，所以反转
df['f_score'] = pd.qcut(df['frequency'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5])
df['m_score'] = pd.qcut(df['monetary'].rank(method='first'), 5, labels=[1, 2, 3, 4, 5])

# 综合标签
df['rfm_score'] = df['r_score'].astype(str) + df['f_score'].astype(str) + df['m_score'].astype(str)
```

使用 AskUserQuestion 确认：
- "RFM 评分完成，是否需要调整评分分位数或确认评分分布合理？"

**⏸️ 等待用户确认后进入 Step 3。**

## Step 3: 客户群体划分

根据 RFM 评分组合定义客户群体：

| 群体 | R 分 | F 分 | M 分 | 典型特征 |
|------|------|------|------|---------|
| Champions（冠军客户） | 4-5 | 4-5 | 4-5 | 最近购买、高频、高价值 |
| Loyal（忠诚客户） | 3-5 | 3-5 | 3-5 | 稳定消费，品牌认可度高 |
| Potential Loyalist（潜力客户） | 3-5 | 1-3 | 1-3 | 最近有购买，但频次和金额待提升 |
| New Customers（新客户） | 4-5 | 1 | 1-2 | 刚开始消费，需要培养 |
| At Risk（风险客户） | 1-2 | 3-5 | 3-5 | 曾经活跃但近期沉默 |
| Hibernating（休眠客户） | 1-2 | 1-2 | 1-2 | 长期未消费，可能已流失 |
| Lost（流失客户） | 1 | 1-2 | 1-3 | 很久未消费且历史金额低 |

```python
def assign_segment(row):
    r, f, m = int(row['r_score']), int(row['f_score']), int(row['m_score'])
    if r >= 4 and f >= 4 and m >= 4:
        return 'Champions'
    elif r >= 3 and f >= 3 and m >= 3:
        return 'Loyal'
    elif r >= 3 and (f <= 3 or m <= 3):
        return 'Potential Loyalist'
    elif r >= 4 and f == 1:
        return 'New Customers'
    elif r <= 2 and f >= 3 and m >= 3:
        return 'At Risk'
    elif r <= 2 and f <= 2 and m <= 2:
        return 'Hibernating'
    else:
        return 'Others'

df['segment'] = df.apply(assign_segment, axis=1)
```

使用 AskUserQuestion 确认：
- "客户群体划分逻辑如上，分群规则是否符合业务预期？"

**⏸️ 等待用户确认后进入 Step 4。**

## Step 4: 群体画像分析

为每个群体输出统计画像：

```python
import matplotlib.pyplot as plt
import matplotlib

matplotlib.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS']
matplotlib.rcParams['axes.unicode_minus'] = False

# 各群体汇总统计
segment_profile = df.groupby('segment').agg(
    count=('user_id', 'count'),
    avg_recency=('recency', 'mean'),
    avg_frequency=('frequency', 'mean'),
    avg_monetary=('monetary', 'mean'),
    total_revenue=('monetary', 'sum')
).round(2)

segment_profile['pct_users'] = (segment_profile['count'] / len(df) * 100).round(2)
segment_profile['pct_revenue'] = (segment_profile['total_revenue'] / df['monetary'].sum() * 100).round(2)

print(segment_profile)

# 可视化：群体分布
fig, axes = plt.subplots(1, 2, figsize=(14, 6))

segment_profile['count'].plot(kind='bar', ax=axes[0], color='steelblue')
axes[0].set_title('各群体客户数量')
axes[0].set_ylabel('客户数')

segment_profile['pct_revenue'].plot(kind='bar', ax=axes[1], color='coral')
axes[1].set_title('各群体收入占比 (%)')
axes[1].set_ylabel('收入占比')

plt.tight_layout()
plt.savefig('segmentation/segment_distribution.png', dpi=150, bbox_inches='tight')
plt.show()
```

使用 AskUserQuestion 确认：
- "客户分群结果如上，各群体占比和收入贡献是否符合业务直觉？是否需要调整分群规则？"

## Step 5: 针对性策略建议

为每个客户群体输出运营策略：

| 群体 | 目标 | 策略 | 关键行动 |
|------|------|------|---------|
| Champions | 维持并激励推荐 | VIP 专属权益 + 推荐奖励 | 发放高额优惠券、邀请内测新品 |
| Loyal | 提升客单价 | 交叉销售 + 向上销售 | 推荐关联商品、提供套餐优惠 |
| Potential Loyalist | 提升频次 | 定期触达 + 复购激励 | 周期性优惠推送、积分加速 |
| New Customers | 培养购买习惯 | 新手引导 + 首单后跟进 | 新人礼包、教程推送、满减券 |
| At Risk | 唤回防流失 | 流失预警 + 挽回优惠 | 个性化召回邮件、限时大额优惠 |
| Hibernating | 低成本激活 | 自动化唤醒 + 清仓促销 | 批量触达、低成本短信/邮件 |

使用 AskUserQuestion 确认：
- "各群体运营策略如上，是否需要调整方向或补充具体行动项？"

**⏸️ 等待用户确认后进入 Step 6 输出产出物。**

## Step 6: 输出产出物

在 `segmentation/` 目录下生成：

```
segmentation/
├── segmentation-report.md          # 分群分析报告（含画像和策略）
├── rfm_analysis.py                 # 完整的 RFM 分析 Python 代码
├── rfm_scores.sql                  # RFM 原始值计算 SQL
├── segment_distribution.png        # 群体分布可视化（代码运行后生成）
└── action-plan.md                  # 各群体运营行动计划
```

## 成功指标

- RFM 评分覆盖所有有交易记录的客户
- 各群体划分结果符合业务直觉（与运营团队确认）
- Python 代码可直接运行，含完整依赖声明
- 策略建议具体到可落地的行动项

## 失败指标

- 分群结果过于集中（某一群体占比超过 60%）
- 缺少群体间差异的统计验证
- 策略建议笼统不可执行

<IMPORTANT>
客户分群的价值在于差异化运营，不在于技术复杂度。始终：
1. 用业务语言解释分群结果，不堆砌统计术语
2. 每个群体必须有明确的运营行动项
3. 关注群体间的差异是否具有统计显著性（t-test / ANOVA, p<0.05）
4. 定期更新分群结果，客户群体是动态变化的
</IMPORTANT>
