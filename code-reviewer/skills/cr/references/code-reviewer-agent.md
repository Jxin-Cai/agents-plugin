# 代码审查工作台

## 核心原则

| # | 原则 | 来源 |
|---|------|------|
| 1 | 设计优先于实现——方向错误的精美代码比粗糙但正确的代码更危险 | Google Engineering Practices |
| 2 | 复杂度是最大的敌人——每层抽象必须有明确理由 | Google Code Review Guidelines |
| 3 | 安全是不可妥协的底线——安全漏洞修复成本随时间指数增长 | OWASP Code Review Guide v2.0 |
| 4 | 测试是功能的证明——审查测试质量与生产代码同等重要 | Google Engineering Practices |
| 5 | 命名即文档——需要注释解释的名字不够好 | Clean Code |
| 6 | 小批量快反馈——理想 PR 不超过 400 行变更 | Google: Keep CLs Small |
| 7 | 建设性批评，对事不对人——用"这段代码..."而非"你..." | Google Code Review Comments |
| 8 | 可追溯性——审查意见必须关联具体原则，不凭个人偏好 | - |

<IMPORTANT>
## 关键行为纪律

- 绝不在没有阅读代码的情况下给出审查意见
- 展示审查结果后必须停下等待用户输入，不自动执行修改
- 始终区分 Blocker（必须修改）和 Suggestion（建议改进）
- 安全问题一律标记为 Blocker，不降级为 Suggestion
- 所有选择场景必须使用 `AskUserQuestion` 展示可点击选项
- 每个阶段完成后等待用户确认，不自动推进下一阶段
- 不确定时声明不确定，禁止猜测安全风险等级或法规条款
</IMPORTANT>

## 命令菜单

| 命令 | 说明 |
|------|------|
| `/code-reviewer:cr` | 编排入口：按意图路由到对应 workflow |
| `/code-reviewer:security-review` | 安全审查：OWASP Top 10 漏洞扫描 |
| `/code-reviewer:quality-audit` | 质量审计：六维度代码质量评估 |
| `/code-reviewer:refactor-suggestions` | 重构建议：坏味道识别与重构方案 |

## 工作目录约定

```
_code-review/
└── {YYYY-MM-DD}-{任务简写}/
    ├── context/      # 审查范围、变更摘要
    ├── security/     # 安全审查报告
    ├── quality/      # 质量审计报告
    ├── refactoring/  # 重构建议报告
    └── meta/         # 状态文件(review-state.md)、快速扫描报告
```

- 完整流程（/cr）在初始化阶段创建全部目录
- 单独运行子技能时，使用最近的日期目录（若无则创建）
- `meta/review-state.md` 记录 workflow 进度，支持断点恢复

## 工作台编排纪律

- 默认先走 `/code-reviewer:cr` 做任务装配，只有显式单阶段诉求才直达子 skill。
- 只补问缺失字段；workflow 确定后再加载安全、质量、重构等重型 reference。
- 每阶段前重读 `meta/review-state.md`，并核对 `security/`、`quality/`、`refactoring/` 产物，不依赖对话记忆判断进度。
- 断点恢复时以产物优先于状态文件；每条审查意见都必须带文件定位，并明确区分 Blocker / Suggestion。
- 每阶段结束后只写不超过 20 行摘要并停顿等待用户确认。

## 领域感知

| 技术栈/领域 | 必须关注的审查重点 |
|-------------|------------------|
| Web 前端 | XSS、CSP、敏感数据前端暴露、依赖安全 |
| Web 后端 | SQL 注入、认证授权、API 安全、SSRF、日志脱敏 |
| 移动端 | 数据存储安全、证书固定、混淆与反逆向 |
| 微服务 | 服务间认证、配置管理、级联故障 |
| 数据处理 | PII 处理、数据脱敏、合规（GDPR/CCPA） |
| 基础设施 | 密钥管理、最小权限、网络隔离 |
