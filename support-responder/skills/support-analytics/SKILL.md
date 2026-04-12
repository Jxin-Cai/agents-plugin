---
name: support-analytics
description: 支持数据分析——绩效指标、趋势分析、改进建议和 Python 分析代码
argument-hint: "<分析目标描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion"]
---

# 支持数据分析

建立客户支持数据分析体系，包括关键绩效指标计算、工单趋势分析、客服绩效评估和改进建议生成，用数据驱动支持体系持续优化。

---

加载引用资料：

```
@references/support-analytics-principles.md
@references/analytics-code-template.md
```

---

## 强制执行规则

1. **每个指标必须有明确的计算公式和数据来源**——不可量化的指标不是指标
2. **分析必须产出可执行的改进建议**——只展示数据不给方向的分析没有价值
3. **Python 代码必须可直接运行**——提供完整的类定义和示例数据
4. **所有交互使用中文**
5. **输出包含分析报告（Markdown）和分析代码（Python）**

---

## 前置条件

- Read `context/business-context.md`（必须存在），提取产品类型、团队规模、当前使用的工单系统
- Glob `tickets/` 检查是否有工单处理框架产出，有则 Read `tickets/sla-config.yaml` 获取 SLA 基准

---

## Step 1: 支持绩效指标定义

Read `context/business-context.md` 提取团队规模和工单系统类型。按客户体验（CSAT/NPS/CES）、效率（FRT/ART/FCR/SLA%）、运营（Backlog/SSR/Reopen%）三个维度，逐个定义指标名称、计算公式、数据来源字段、目标值和警戒线，Write 输出到 `analytics/kpi-definitions.md`：

### 客户体验指标

| 指标 | 英文缩写 | 计算公式 | 目标值 |
|------|----------|----------|--------|
| 客户满意度 | CSAT | 满意评价数 / 总评价数 × 5 | ≥ 4.5 |
| 净推荐值 | NPS | 推荐者% - 贬损者% | ≥ 50 |
| 客户费力度 | CES | 低费力评价数 / 总评价数 | ≥ 70% |

### 效率指标

| 指标 | 英文缩写 | 计算公式 | 目标值 |
|------|----------|----------|--------|
| 首次响应时间 | FRT | 工单创建到首次回复的中位数 | < 2h |
| 平均解决时间 | ART | 工单创建到解决的中位数 | < 24h |
| 首次解决率 | FCR | 一次性解决工单数 / 总工单数 | ≥ 80% |
| SLA 合规率 | SLA% | SLA 内完成工单数 / 总工单数 | ≥ 95% |

### 运营指标

| 指标 | 英文缩写 | 计算公式 | 目标值 |
|------|----------|----------|--------|
| 工单积压量 | Backlog | 未解决工单总数 | 趋势下降 |
| 自助解决率 | SSR | 知识库解决数 / (知识库解决数 + 工单数) | ≥ 40% |
| 重开率 | Reopen% | 重新打开工单数 / 已关闭工单数 | < 5% |

输出文件：`analytics/kpi-definitions.md`

<AskUserQuestion>
您的工单系统能导出哪些数据？（例如：工单创建/关闭时间、响应时间、满意度评分、分类标签等）
这将帮助我确定哪些指标可以立即分析，哪些需要先建立数据收集机制。
</AskUserQuestion>

---

## Step 2: 工单量趋势分析

Read `analytics/kpi-definitions.md`（Step 1 产出）获取指标定义。按时间趋势（日/周/月+工作日/周末+小时级分布）、分类趋势（各类型占比变化+新增类型）、渠道趋势（各渠道分布+迁移）、相关性分析（产品发布关联+季节性+异常检测）四个维度建模，Write 输出到 `analytics/trend-analysis-model.md`：

### 分析维度

1. **时间趋势**
   - 日/周/月工单量变化
   - 工作日 vs 周末分布
   - 小时级分布（定位高峰时段）

2. **分类趋势**
   - 各类型问题占比变化
   - 新增问题类型识别
   - 已解决问题类型的工单下降验证

3. **渠道趋势**
   - 各渠道工单量分布
   - 渠道间迁移趋势
   - 自助渠道使用率变化

4. **相关性分析**
   - 产品发布 → 工单量峰值
   - 季节性波动识别
   - 异常值检测和归因

输出文件：`analytics/trend-analysis-model.md`

---

## Step 3: 常见问题分类统计

Read `analytics/trend-analysis-model.md`（Step 2 产出）获取分析维度。若 `tickets/routing-rules.yaml` 存在则 Read 获取工单分类。为每个分类统计工单数量/占比/平均解决时间/FCR/CSAT，并设计异常检测规则（量突增→Bug、时间变长→培训缺口、满意度下降→话术问题），Write 输出到 `analytics/category-stats-framework.md`：

### 分类统计框架

```
问题分类 Top N
├── 各分类工单数量和占比
├── 各分类平均解决时间
├── 各分类首次解决率
├── 各分类客户满意度
└── 趋势对比（本月 vs 上月）
```

### 异常检测

- 某类问题工单量突然上升 → 可能是产品 Bug
- 某类问题解决时间变长 → 可能需要培训或流程优化
- 某类问题满意度下降 → 可能需要改进话术或方案

输出文件：`analytics/category-stats-framework.md`

---

## Step 4: 客服绩效分析

Read `analytics/kpi-definitions.md` 获取指标定义。设计个人绩效看板（处理量20%+响应速度20%+解决速度15%+FCR 20%+CSAT 25% 加权评分）和团队绩效看板（KPI达成+成员对比雷达图+负载均衡基尼系数+技能覆盖热力图），Write 输出到 `analytics/performance-model.md`：

### 个人绩效看板

| 指标 | 权重 | 说明 |
|------|------|------|
| 处理量 | 20% | 已解决工单数 |
| 响应速度 | 20% | 首次响应时间中位数 |
| 解决速度 | 15% | 平均解决时间 |
| 首次解决率 | 20% | 一次性解决比例 |
| 客户满意度 | 25% | CSAT 评分 |

### 团队绩效看板

- 团队整体 KPI 达成情况
- 成员间对比（雷达图）
- 负载均衡度（基尼系数）
- 技能覆盖热力图

输出文件：`analytics/performance-model.md`

---

## Step 5: 改进建议生成

Read `analytics/kpi-definitions.md` 和 `analytics/category-stats-framework.md` 获取指标和分类数据。按"触发指标→当前值→目标值→根因分析→行动项(负责人/截止)→预期效果→验证方式"格式生成建议规则引擎，Write 输出到 `analytics/improvement-engine.md`：

### 建议生成规则

```python
# 示例规则引擎
if fcr < 0.8:
    suggest("提升首次解决率", [
        "分析重复工单的根因",
        "补充 T1 知识库覆盖",
        "加强客服培训"
    ])

if sla_compliance < 0.95:
    suggest("改善 SLA 合规率", [
        "排查超时工单集中的类型/时段",
        "调整路由规则分散负载",
        "增加高峰时段人力"
    ])

if csat < 4.5:
    suggest("提升客户满意度", [
        "分析低分工单的共同特征",
        "优化沟通模板和话术",
        "建立客户回访机制"
    ])
```

输出文件：`analytics/improvement-engine.md`

---

## Step 6: Python 分析代码生成

Read `analytics/kpi-definitions.md` 和 `analytics/performance-model.md` 获取指标定义和绩效模型。基于 `@references/analytics-code-template.md` 中的 `SupportAnalytics` 类，生成完整可运行的 Python 脚本，包含数据加载/清洗、指标计算、matplotlib 可视化、Markdown 报告输出和示例数据演示，Write 输出到 `analytics/support_analytics.py`：

- `SupportAnalytics` 类定义
- 数据加载和清洗
- 指标计算方法
- 可视化图表生成（matplotlib/plotly）
- 报告自动生成（Markdown 输出）
- 示例数据和运行演示

输出文件：`analytics/support_analytics.py`

---

## 最终输出

`analytics/` 目录下应包含：
- `kpi-definitions.md` — 关键指标定义
- `trend-analysis-model.md` — 趋势分析模型
- `category-stats-framework.md` — 分类统计框架
- `performance-model.md` — 绩效分析模型
- `improvement-engine.md` — 改进建议引擎
- `support_analytics.py` — Python 分析代码

---

## 成功指标

- [ ] 所有 KPI 有明确的计算公式和数据来源字段
- [ ] Python 代码可直接运行，输入示例数据能产出报告
- [ ] 改进建议包含负责人、截止日期和验证方式

## 失败指标

- 定义了无法从现有系统获取数据的指标
- Python 代码缺少依赖说明或无法运行
- 改进建议不可操作（缺少具体行动项）

---

**IMPORTANT**: 数据分析的目的不是生成好看的报表，而是找到"下一步该做什么"。每个分析结论都必须指向一个具体的行动。如果一个图表不能回答"所以呢？"这个问题，就不要画它。
