# 支持数据分析原则与参考

## 关键支持指标定义和计算方法

### CSAT（客户满意度评分）

```
CSAT = (满意评价数 / 总评价数) × 5

评价等级映射：
  5 星 = 非常满意
  4 星 = 满意
  3 星 = 一般
  2 星 = 不满意
  1 星 = 非常不满意

健康范围：≥ 4.5 / 5
警戒线：< 4.0 / 5
```

### FCR（首次解决率）

```
FCR = 首次联系即解决的工单数 / 总工单数 × 100%

判定"首次解决"的条件：
  1. 工单未被重新打开
  2. 客户未在 72h 内就同一问题再次联系
  3. 工单未被升级到更高层级

健康范围：≥ 80%
警戒线：< 65%
```

### FRT（首次响应时间）

```
FRT = 工单创建时间戳 → 首次人工回复时间戳 的时间差

注意：
  - 自动回复不算首次响应
  - 按工作时间还是自然时间计算需与 SLA 一致
  - 使用中位数而非平均值（避免异常值干扰）

健康范围（综合）：< 2 小时
按渠道细分见渠道 SLA 基准
```

### ART（平均解决时间）

```
ART = 工单创建时间戳 → 状态变为"已解决"时间戳 的时间差

注意：
  - 扣除"等待客户"状态的时间
  - 按问题类型和优先级分别计算
  - 使用中位数 + P90

健康范围：< 24 小时（综合）
```

---

## Python 分析代码模板

```python
"""
客户支持数据分析工具

依赖安装：
  pip install pandas matplotlib plotly

使用方法：
  analyzer = SupportAnalytics(ticket_data)
  report = analyzer.generate_report()
"""

import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from typing import Optional
from dataclasses import dataclass


@dataclass
class KPIResult:
    """KPI 计算结果"""
    name: str
    value: float
    target: float
    unit: str
    status: str  # 'healthy', 'warning', 'critical'
    trend: str   # 'up', 'down', 'stable'

    @property
    def is_healthy(self) -> bool:
        return self.status == 'healthy'


class SupportAnalytics:
    """客户支持数据分析器"""

    def __init__(self, tickets_df: pd.DataFrame):
        """
        初始化分析器

        tickets_df 必须包含以下列：
        - ticket_id: 工单ID
        - created_at: 创建时间 (datetime)
        - first_response_at: 首次响应时间 (datetime)
        - resolved_at: 解决时间 (datetime, nullable)
        - closed_at: 关闭时间 (datetime, nullable)
        - category: 问题分类
        - priority: 优先级 (P0/P1/P2/P3)
        - channel: 渠道
        - assignee: 处理人
        - tier: 处理层级 (T1/T2/T3)
        - csat_score: 满意度评分 (1-5, nullable)
        - is_reopened: 是否重新打开 (bool)
        - is_escalated: 是否被升级 (bool)
        """
        self.df = tickets_df.copy()
        self._preprocess()

    def _preprocess(self):
        """数据预处理"""
        # 时间列转换
        time_cols = ['created_at', 'first_response_at', 'resolved_at', 'closed_at']
        for col in time_cols:
            if col in self.df.columns:
                self.df[col] = pd.to_datetime(self.df[col])

        # 计算衍生字段
        self.df['frt_hours'] = (
            (self.df['first_response_at'] - self.df['created_at'])
            .dt.total_seconds() / 3600
        )
        self.df['resolution_hours'] = (
            (self.df['resolved_at'] - self.df['created_at'])
            .dt.total_seconds() / 3600
        )
        self.df['created_date'] = self.df['created_at'].dt.date
        self.df['created_hour'] = self.df['created_at'].dt.hour
        self.df['created_weekday'] = self.df['created_at'].dt.day_name()

    # ---- 核心指标计算 ----

    def calc_csat(self) -> KPIResult:
        """计算客户满意度"""
        scores = self.df['csat_score'].dropna()
        if scores.empty:
            return KPIResult('CSAT', 0, 4.5, '/ 5', 'critical', 'stable')
        avg = scores.mean()
        status = 'healthy' if avg >= 4.5 else ('warning' if avg >= 4.0 else 'critical')
        return KPIResult('CSAT', round(avg, 2), 4.5, '/ 5', status, 'stable')

    def calc_fcr(self) -> KPIResult:
        """计算首次解决率"""
        total = len(self.df)
        if total == 0:
            return KPIResult('FCR', 0, 80, '%', 'critical', 'stable')
        first_contact = self.df[
            (~self.df['is_reopened']) & (~self.df['is_escalated'])
        ]
        rate = len(first_contact) / total * 100
        status = 'healthy' if rate >= 80 else ('warning' if rate >= 65 else 'critical')
        return KPIResult('FCR', round(rate, 1), 80, '%', status, 'stable')

    def calc_frt(self) -> KPIResult:
        """计算首次响应时间中位数"""
        frt = self.df['frt_hours'].dropna()
        if frt.empty:
            return KPIResult('FRT', 0, 2, 'h', 'critical', 'stable')
        median = frt.median()
        status = 'healthy' if median <= 2 else ('warning' if median <= 4 else 'critical')
        return KPIResult('FRT', round(median, 2), 2, 'h', status, 'stable')

    def calc_art(self) -> KPIResult:
        """计算平均解决时间中位数"""
        art = self.df['resolution_hours'].dropna()
        if art.empty:
            return KPIResult('ART', 0, 24, 'h', 'critical', 'stable')
        median = art.median()
        status = 'healthy' if median <= 24 else ('warning' if median <= 48 else 'critical')
        return KPIResult('ART', round(median, 2), 24, 'h', status, 'stable')

    def calc_sla_compliance(self, sla_hours: dict = None) -> KPIResult:
        """计算 SLA 合规率"""
        if sla_hours is None:
            sla_hours = {'P0': 4, 'P1': 8, 'P2': 24, 'P3': 72}
        resolved = self.df[self.df['resolved_at'].notna()].copy()
        if resolved.empty:
            return KPIResult('SLA', 0, 95, '%', 'critical', 'stable')
        resolved['sla_limit'] = resolved['priority'].map(sla_hours)
        compliant = resolved[resolved['resolution_hours'] <= resolved['sla_limit']]
        rate = len(compliant) / len(resolved) * 100
        status = 'healthy' if rate >= 95 else ('warning' if rate >= 85 else 'critical')
        return KPIResult('SLA', round(rate, 1), 95, '%', status, 'stable')

    # ---- 趋势分析 ----

    def ticket_volume_trend(self, period: str = 'D') -> pd.DataFrame:
        """工单量趋势（日/周/月）"""
        return (
            self.df
            .set_index('created_at')
            .resample(period)['ticket_id']
            .count()
            .reset_index()
            .rename(columns={'ticket_id': 'count'})
        )

    def hourly_distribution(self) -> pd.Series:
        """小时级工单分布"""
        return self.df.groupby('created_hour')['ticket_id'].count()

    def category_breakdown(self) -> pd.DataFrame:
        """问题分类统计"""
        stats = self.df.groupby('category').agg(
            count=('ticket_id', 'count'),
            avg_resolution_hours=('resolution_hours', 'median'),
            fcr_rate=('is_reopened', lambda x: (1 - x.mean()) * 100),
            avg_csat=('csat_score', 'mean')
        ).round(2)
        stats['percentage'] = (stats['count'] / stats['count'].sum() * 100).round(1)
        return stats.sort_values('count', ascending=False)

    # ---- 客服绩效 ----

    def agent_performance(self) -> pd.DataFrame:
        """客服个人绩效"""
        perf = self.df.groupby('assignee').agg(
            ticket_count=('ticket_id', 'count'),
            median_frt=('frt_hours', 'median'),
            median_art=('resolution_hours', 'median'),
            fcr_rate=('is_reopened', lambda x: (1 - x.mean()) * 100),
            avg_csat=('csat_score', 'mean')
        ).round(2)
        return perf.sort_values('avg_csat', ascending=False)

    # ---- 改进建议 ----

    def generate_suggestions(self) -> list[str]:
        """基于数据生成改进建议"""
        suggestions = []
        kpis = {
            'csat': self.calc_csat(),
            'fcr': self.calc_fcr(),
            'frt': self.calc_frt(),
            'art': self.calc_art(),
            'sla': self.calc_sla_compliance()
        }

        if not kpis['fcr'].is_healthy:
            suggestions.append(
                f"⚠️ 首次解决率 {kpis['fcr'].value}% 低于目标 {kpis['fcr'].target}%。"
                f"建议：1) 分析重复工单根因 2) 补充 T1 知识库 3) 加强培训"
            )
        if not kpis['frt'].is_healthy:
            suggestions.append(
                f"⚠️ 首次响应时间 {kpis['frt'].value}h 超过目标 {kpis['frt'].target}h。"
                f"建议：1) 排查高峰时段人力缺口 2) 优化自动分配规则 3) 增加自助渠道覆盖"
            )
        if not kpis['csat'].is_healthy:
            suggestions.append(
                f"⚠️ 客户满意度 {kpis['csat'].value}/5 低于目标 {kpis['csat'].target}/5。"
                f"建议：1) 分析低分工单共同特征 2) 优化沟通话术 3) 建立回访机制"
            )
        if not kpis['sla'].is_healthy:
            suggestions.append(
                f"⚠️ SLA 合规率 {kpis['sla'].value}% 低于目标 {kpis['sla'].target}%。"
                f"建议：1) 排查超时集中的类型/时段 2) 调整路由分散负载 3) 增加高峰人力"
            )

        # 分类维度建议
        cats = self.category_breakdown()
        top_cat = cats.index[0] if not cats.empty else None
        if top_cat and cats.loc[top_cat, 'percentage'] > 30:
            suggestions.append(
                f"📊 「{top_cat}」占工单总量 {cats.loc[top_cat, 'percentage']}%，"
                f"建议优先优化该类问题的知识库和自助解决方案。"
            )

        if not suggestions:
            suggestions.append("✅ 所有核心指标达标，继续保持！建议关注趋势变化。")

        return suggestions

    # ---- 报告生成 ----

    def generate_report(self) -> str:
        """生成 Markdown 格式分析报告"""
        kpis = [
            self.calc_csat(),
            self.calc_fcr(),
            self.calc_frt(),
            self.calc_art(),
            self.calc_sla_compliance()
        ]

        report = f"# 客户支持分析报告\n\n"
        report += f"> 生成时间：{datetime.now().strftime('%Y-%m-%d %H:%M')}\n"
        report += f"> 数据范围：{self.df['created_at'].min().date()} ~ {self.df['created_at'].max().date()}\n"
        report += f"> 工单总量：{len(self.df)}\n\n"

        report += "## 核心指标\n\n"
        report += "| 指标 | 当前值 | 目标值 | 状态 |\n"
        report += "|------|--------|--------|------|\n"
        status_emoji = {'healthy': '🟢', 'warning': '🟡', 'critical': '🔴'}
        for kpi in kpis:
            emoji = status_emoji.get(kpi.status, '⚪')
            report += f"| {kpi.name} | {kpi.value} {kpi.unit} | {kpi.target} {kpi.unit} | {emoji} |\n"

        report += "\n## 问题分类 Top 10\n\n"
        cats = self.category_breakdown().head(10)
        report += cats.to_markdown() + "\n"

        report += "\n## 改进建议\n\n"
        for s in self.generate_suggestions():
            report += f"- {s}\n"

        return report


# ---- 示例数据和运行演示 ----

def create_sample_data(n=200) -> pd.DataFrame:
    """生成示例工单数据"""
    import numpy as np
    np.random.seed(42)

    categories = ['登录问题', '付款失败', '功能异常', '账号管理', '数据导出',
                   '性能问题', '权限设置', '计费咨询']
    channels = ['在线聊天', '邮件', '应用内消息', '电话']
    priorities = ['P0', 'P1', 'P2', 'P3']
    agents = ['张三', '李四', '王五', '赵六', '陈七']
    tiers = ['T1', 'T2', 'T3']

    data = []
    base_time = datetime(2026, 3, 1)

    for i in range(n):
        created = base_time + timedelta(
            days=np.random.randint(0, 30),
            hours=np.random.randint(8, 22),
            minutes=np.random.randint(0, 60)
        )
        frt_minutes = np.random.exponential(60)
        resolution_hours = np.random.exponential(12)

        data.append({
            'ticket_id': f'T-{i+1:04d}',
            'created_at': created,
            'first_response_at': created + timedelta(minutes=frt_minutes),
            'resolved_at': created + timedelta(hours=resolution_hours),
            'closed_at': created + timedelta(hours=resolution_hours + 2),
            'category': np.random.choice(categories, p=[0.2, 0.15, 0.15, 0.15, 0.1, 0.1, 0.08, 0.07]),
            'priority': np.random.choice(priorities, p=[0.05, 0.15, 0.5, 0.3]),
            'channel': np.random.choice(channels, p=[0.35, 0.25, 0.25, 0.15]),
            'assignee': np.random.choice(agents),
            'tier': np.random.choice(tiers, p=[0.7, 0.2, 0.1]),
            'csat_score': np.random.choice([1, 2, 3, 4, 5], p=[0.02, 0.05, 0.13, 0.35, 0.45]),
            'is_reopened': np.random.random() < 0.08,
            'is_escalated': np.random.random() < 0.12,
        })

    return pd.DataFrame(data)


if __name__ == '__main__':
    df = create_sample_data()
    analyzer = SupportAnalytics(df)
    print(analyzer.generate_report())
```

---

## 趋势识别方法

### 移动平均异常检测

```python
def detect_anomaly(series: pd.Series, window: int = 7, threshold: float = 2.0):
    """
    基于移动平均的异常检测

    参数：
    - series: 时间序列数据
    - window: 移动窗口大小
    - threshold: 标准差倍数阈值

    返回异常点索引列表
    """
    rolling_mean = series.rolling(window=window).mean()
    rolling_std = series.rolling(window=window).std()
    upper = rolling_mean + threshold * rolling_std
    lower = rolling_mean - threshold * rolling_std
    anomalies = series[(series > upper) | (series < lower)]
    return anomalies.index.tolist()
```

### 趋势判定规则

```
上升趋势：连续 3 个周期环比增长 > 5%
下降趋势：连续 3 个周期环比下降 > 5%
稳定：波动幅度在 ±10% 以内
异常：单周期偏离移动平均 > 2 个标准差
```

---

## 主动外展触发条件

基于数据分析自动识别需要主动联系客户的场景：

| 触发条件 | 行动 | 优先级 |
|----------|------|--------|
| 同一客户 30 天内 3+ 次工单 | 主动联系了解根因，安排专属对接人 | 高 |
| 客户 CSAT 连续 2 次 ≤ 2 | 管理层介入，了解不满原因并修复 | 高 |
| 高价值客户首次工单 | 优先处理 + 48h 后跟进确认 | 中 |
| 客户使用率骤降 50%+ | 客户成功团队主动联系 | 中 |
| 工单解决后 7 天内重开 | 分配资深客服重新处理 + 根因分析 | 中 |

---

## 改进建议框架

### 建议优先级矩阵

```
影响大 + 实施易 → 立即执行（Quick Win）
影响大 + 实施难 → 规划排期（Strategic）
影响小 + 实施易 → 有空再做（Fill-in）
影响小 + 实施难 → 暂不考虑（Deprioritize）
```

### 建议输出格式

```markdown
### 建议：{标题}

- **触发指标**：{哪个 KPI 不达标}
- **当前值 → 目标值**：{具体数字}
- **根因分析**：{数据支撑的原因}
- **行动项**：
  1. {具体行动 1}（负责人 / 截止日期）
  2. {具体行动 2}（负责人 / 截止日期）
- **预期效果**：{预计改善幅度}
- **验证方式**：{如何确认改进生效}
```

### 周期性分析节奏

| 频率 | 分析内容 | 输出物 |
|------|----------|--------|
| 每日 | KPI 仪表盘刷新 + 异常告警 | 告警通知 |
| 每周 | 工单趋势 + 分类统计 + 团队绩效 | 周报 |
| 每月 | 深度分析 + 改进建议 + 知识库审查 | 月度报告 |
| 每季 | 战略级回顾 + 体系优化 + 预算规划 | 季度报告 |
