# 客户分群分析原则与参考

## RFM 模型详解

### 概述

RFM（Recency, Frequency, Monetary）是经典的客户价值分析模型，通过三个维度量化客户价值：

- **Recency（最近消费时间）** — 客户最近一次购买距今多久。越近表明客户越活跃。
- **Frequency（消费频次）** — 在分析时间窗口内客户购买了多少次。频次越高表明忠诚度越高。
- **Monetary（消费金额）** — 在分析时间窗口内客户累计消费金额。金额越高表明价值越大。

### 评分方法

#### 分位数评分法（推荐）

基于数据分布的分位数划分，适应不同业务场景：

```python
# 使用 pandas qcut 基于分位数自动划分
# 注意：Recency 越小越好，需要反转标签
df['r_score'] = pd.qcut(df['recency'], q=5, labels=[5, 4, 3, 2, 1])
df['f_score'] = pd.qcut(df['frequency'].rank(method='first'), q=5, labels=[1, 2, 3, 4, 5])
df['m_score'] = pd.qcut(df['monetary'].rank(method='first'), q=5, labels=[1, 2, 3, 4, 5])
```

优势：
- 自动适应数据分布，不需要手动设置阈值
- 每个分数段的客户数量大致相等
- 适用于不同规模和行业的数据

#### 业务规则评分法

根据业务经验设置固定阈值：

```python
def score_recency(days):
    if days <= 7: return 5
    elif days <= 30: return 4
    elif days <= 90: return 3
    elif days <= 180: return 2
    else: return 1

def score_frequency(count):
    if count >= 20: return 5
    elif count >= 10: return 4
    elif count >= 5: return 3
    elif count >= 2: return 2
    else: return 1

def score_monetary(amount):
    if amount >= 10000: return 5
    elif amount >= 5000: return 4
    elif amount >= 1000: return 3
    elif amount >= 200: return 2
    else: return 1
```

### 分群逻辑

RFM 三维评分组合产生 125 种可能（5^3），需要合并为有业务意义的群体：

```python
segment_map = {
    'Champions':         lambda r, f, m: r >= 4 and f >= 4 and m >= 4,
    'Loyal':             lambda r, f, m: r >= 3 and f >= 3 and m >= 3 and not (r >= 4 and f >= 4 and m >= 4),
    'Potential Loyalist':lambda r, f, m: r >= 3 and (f <= 3 or m <= 3) and f >= 2,
    'New Customers':     lambda r, f, m: r >= 4 and f <= 1,
    'Promising':         lambda r, f, m: r >= 3 and f <= 2 and m >= 3,
    'Need Attention':    lambda r, f, m: r == 3 and f == 3 and m <= 2,
    'About to Sleep':    lambda r, f, m: r == 2 and f >= 2 and m >= 2,
    'At Risk':           lambda r, f, m: r <= 2 and f >= 3 and m >= 3,
    'Cannot Lose':       lambda r, f, m: r <= 2 and f >= 4 and m >= 4,
    'Hibernating':       lambda r, f, m: r <= 2 and f <= 2 and m <= 2,
    'Lost':              lambda r, f, m: r == 1 and f <= 2 and m <= 2,
}
```

## K-Means 聚类方法

当 RFM 分群不够精细或需要数据驱动的分群时，使用 K-Means 聚类：

```python
from sklearn.preprocessing import StandardScaler
from sklearn.cluster import KMeans
from sklearn.metrics import silhouette_score
import matplotlib.pyplot as plt

# 标准化
scaler = StandardScaler()
rfm_scaled = scaler.fit_transform(df[['recency', 'frequency', 'monetary']])

# 肘部法则确定最佳 K
inertias = []
silhouettes = []
K_range = range(2, 11)

for k in K_range:
    km = KMeans(n_clusters=k, random_state=42, n_init=10)
    km.fit(rfm_scaled)
    inertias.append(km.inertia_)
    silhouettes.append(silhouette_score(rfm_scaled, km.labels_))

# 可视化
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
ax1.plot(K_range, inertias, 'bx-')
ax1.set_title('肘部法则')
ax1.set_xlabel('K')
ax1.set_ylabel('SSE')

ax2.plot(K_range, silhouettes, 'rx-')
ax2.set_title('轮廓系数')
ax2.set_xlabel('K')
ax2.set_ylabel('Silhouette Score')

plt.tight_layout()
plt.savefig('segmentation/elbow_silhouette.png', dpi=150)
plt.show()

# 选择最佳 K 后训练模型
best_k = silhouettes.index(max(silhouettes)) + 2
km_final = KMeans(n_clusters=best_k, random_state=42, n_init=10)
df['cluster'] = km_final.fit_predict(rfm_scaled)
```

## 群体标签定义与行为特征

| 群体 | 占比基准 | 收入贡献基准 | 行为特征 |
|------|---------|------------|---------|
| Champions | 5-10% | 25-35% | 高频高额，对品牌高度忠诚，是口碑传播者 |
| Loyal | 15-25% | 30-40% | 稳定消费，对价格敏感度低，愿意尝试新品 |
| Potential Loyalist | 10-15% | 10-15% | 近期有消费，购买力待释放，需要正确引导 |
| New Customers | 5-10% | 3-5% | 处于试探期，体验好坏直接决定后续行为 |
| At Risk | 10-15% | 10-15% | 消费频率下降，可能被竞品吸引，挽回窗口有限 |
| Hibernating | 15-25% | 3-5% | 长期沉默，唤醒成本高，但基数大值得尝试 |
| Lost | 10-20% | 1-2% | 基本流失，投入产出比低，做好自然淘汰 |

## 各群体运营策略

### Champions（冠军客户）

**目标**: 维持忠诚、激励推荐

| 策略 | 具体行动 | 预期效果 |
|------|---------|---------|
| VIP 权益 | 专属客服、优先发货、生日礼遇 | 提升满意度和留存 |
| 推荐计划 | 推荐返现/积分、社交分享激励 | 低成本获客 |
| 新品内测 | 邀请试用新品、收集反馈 | 提升参与感 |
| 专属活动 | 线下见面会、高端体验活动 | 强化品牌关系 |

### Loyal（忠诚客户）

**目标**: 提升客单价

| 策略 | 具体行动 | 预期效果 |
|------|---------|---------|
| 交叉销售 | 基于购买历史推荐关联商品 | 提升 ARPU |
| 会员升级 | 达标提升会员等级、解锁更多权益 | 激励消费升级 |
| 套餐组合 | 高频商品 + 利润品捆绑 | 提升毛利率 |

### At Risk（风险客户）

**目标**: 挽回防流失

| 策略 | 具体行动 | 预期效果 |
|------|---------|---------|
| 预警触达 | 沉默 N 天自动触发唤回消息 | 及时干预 |
| 挽回优惠 | 个性化大额优惠券（限时使用） | 刺激回购 |
| 问卷调研 | 了解沉默原因，收集改进建议 | 优化产品/服务 |
| 专属客服 | 一对一回访，解决历史问题 | 挽回信任 |

### Hibernating（休眠客户）

**目标**: 低成本激活

| 策略 | 具体行动 | 预期效果 |
|------|---------|---------|
| 自动化唤醒 | 批量短信/邮件，推送清仓或热门商品 | 低成本触达 |
| 重新注册激励 | 视为新客，提供新人级别优惠 | 激活沉睡账号 |
| 数据清洗 | 超过 N 个月无响应标记为流失 | 优化资源分配 |
