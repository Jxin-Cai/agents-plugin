# Python 分析代码模板

> 依赖：`pip install pandas matplotlib plotly`

```python
"""客户支持数据分析工具"""
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta
from dataclasses import dataclass

@dataclass
class KPIResult:
    name: str; value: float; target: float; unit: str; status: str; trend: str
    @property
    def is_healthy(self) -> bool: return self.status == 'healthy'

class SupportAnalytics:
    """
    初始化需要 DataFrame 包含以下列：
    ticket_id, created_at, first_response_at, resolved_at, closed_at,
    category, priority(P0-P3), channel, assignee, tier(T1-T3),
    csat_score(1-5), is_reopened(bool), is_escalated(bool)
    """
    def __init__(self, df: pd.DataFrame):
        self.df = df.copy()
        for c in ['created_at','first_response_at','resolved_at','closed_at']:
            if c in self.df.columns: self.df[c] = pd.to_datetime(self.df[c])
        self.df['frt_hours'] = (self.df['first_response_at']-self.df['created_at']).dt.total_seconds()/3600
        self.df['resolution_hours'] = (self.df['resolved_at']-self.df['created_at']).dt.total_seconds()/3600

    def calc_csat(self) -> KPIResult:
        s = self.df['csat_score'].dropna()
        avg = s.mean() if not s.empty else 0
        return KPIResult('CSAT',round(avg,2),4.5,'/5','healthy' if avg>=4.5 else 'warning' if avg>=4.0 else 'critical','stable')

    def calc_fcr(self) -> KPIResult:
        t = len(self.df); r = len(self.df[(~self.df['is_reopened'])&(~self.df['is_escalated'])])/t*100 if t else 0
        return KPIResult('FCR',round(r,1),80,'%','healthy' if r>=80 else 'warning' if r>=65 else 'critical','stable')

    def calc_frt(self) -> KPIResult:
        m = self.df['frt_hours'].dropna().median() if not self.df['frt_hours'].dropna().empty else 0
        return KPIResult('FRT',round(m,2),2,'h','healthy' if m<=2 else 'warning' if m<=4 else 'critical','stable')

    def calc_sla(self, sla_h=None) -> KPIResult:
        sla_h = sla_h or {'P0':4,'P1':8,'P2':24,'P3':72}
        rv = self.df[self.df['resolved_at'].notna()].copy()
        if rv.empty: return KPIResult('SLA',0,95,'%','critical','stable')
        rv['limit'] = rv['priority'].map(sla_h)
        r = len(rv[rv['resolution_hours']<=rv['limit']])/len(rv)*100
        return KPIResult('SLA',round(r,1),95,'%','healthy' if r>=95 else 'warning' if r>=85 else 'critical','stable')

    def category_breakdown(self) -> pd.DataFrame:
        s = self.df.groupby('category').agg(count=('ticket_id','count'),
            avg_hours=('resolution_hours','median'),fcr=('is_reopened',lambda x:(1-x.mean())*100),
            csat=('csat_score','mean')).round(2)
        s['pct'] = (s['count']/s['count'].sum()*100).round(1)
        return s.sort_values('count',ascending=False)

    def agent_performance(self) -> pd.DataFrame:
        return self.df.groupby('assignee').agg(tickets=('ticket_id','count'),
            frt=('frt_hours','median'),art=('resolution_hours','median'),
            fcr=('is_reopened',lambda x:(1-x.mean())*100),csat=('csat_score','mean')).round(2)

    def generate_suggestions(self) -> list[str]:
        kpis = {'csat':self.calc_csat(),'fcr':self.calc_fcr(),'frt':self.calc_frt(),'sla':self.calc_sla()}
        tips = []
        if not kpis['fcr'].is_healthy: tips.append(f"FCR {kpis['fcr'].value}%<{kpis['fcr'].target}%：分析重复工单根因/补T1知识库/加强培训")
        if not kpis['frt'].is_healthy: tips.append(f"FRT {kpis['frt'].value}h>{kpis['frt'].target}h：排查高峰人力缺口/优化自动分配/增自助渠道")
        if not kpis['csat'].is_healthy: tips.append(f"CSAT {kpis['csat'].value}<{kpis['csat'].target}：分析低分共性/优化话术/建立回访")
        if not kpis['sla'].is_healthy: tips.append(f"SLA {kpis['sla'].value}%<{kpis['sla'].target}%：排查超时类型/调整路由/增高峰人力")
        return tips or ["所有核心指标达标，关注趋势变化。"]

    def generate_report(self) -> str:
        kpis = [self.calc_csat(),self.calc_fcr(),self.calc_frt(),self.calc_sla()]
        em = {'healthy':'OK','warning':'WARN','critical':'CRIT'}
        r = f"# 支持分析报告\n> {datetime.now():%Y-%m-%d} | 工单量 {len(self.df)}\n\n"
        r += "| 指标 | 当前 | 目标 | 状态 |\n|---|---|---|---|\n"
        for k in kpis: r += f"| {k.name} | {k.value}{k.unit} | {k.target}{k.unit} | {em[k.status]} |\n"
        r += "\n## 改进建议\n" + "\n".join(f"- {s}" for s in self.generate_suggestions())
        return r
```

## 异常检测方法

```python
def detect_anomaly(series, window=7, threshold=2.0):
    """基于移动平均的异常检测，返回异常点索引"""
    mu = series.rolling(window).mean()
    sd = series.rolling(window).std()
    return series[(series > mu+threshold*sd) | (series < mu-threshold*sd)].index.tolist()
```
