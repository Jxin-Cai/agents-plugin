# Workflow 路由手册

## 路由矩阵

| workflow | 触发关键词 | 加载的子技能 | 预计耗时 |
|----------|-----------|-------------|---------|
| `full-review` | "完整审查"、"全面审查"、意图不明确 | security -> quality -> refactor | 30-60 min |
| `security-focus` | "安全"、"漏洞"、"OWASP"、"渗透" | security-review | 10-20 min |
| `quality-focus` | "质量"、"复杂度"、"坏味道"、"代码质量" | quality-audit | 10-20 min |
| `refactor-focus` | "重构"、"优化结构"、"改进代码" | refactor-suggestions | 15-25 min |
| `quick-scan` | "快速"、"扫一下"、"概览"、"粗看" | 编排器内轻量扫描 | 5-10 min |
| `custom` | 用户明确指定组合 | 按用户选择 | 按组合 |

## 路由规则

1. **精确匹配优先**：关键词明确命中单一 workflow 时直接路由
2. **补问分流**：关键词模糊或可匹配多个 workflow 时，用 `AskUserQuestion` 让用户选择
3. **默认 full-review**：用户只说"帮我看看代码"且无法进一步确认时

## 各 workflow 执行规范

### full-review

- 严格按 security -> quality -> refactor 顺序
- 每阶段结束有门控确认点
- 前一阶段产出传递给后一阶段（如安全发现影响质量评分）

### single-focus（security / quality / refactor）

- 直接调用对应子技能 skill
- 编排器只做初始化和收尾
- 子技能内部自带门控

### quick-scan

- 不调用子技能，编排器内执行
- 安全速览：硬编码凭据、明显注入、危险函数调用
- 质量速览：文件大小统计、最高圈复杂度、重复代码块
- 重构速览：标记最突出的 2-3 个坏味道
- 输出精简报告（不超过 50 行），保存到 `meta/quick-scan-{日期}.md`

## 门控确认模板

每个门控点使用 `AskUserQuestion`，必须提供：

1. 本阶段产出摘要（1-2 句话）
2. 关键发现数量
3. 至少 3 个选项（继续 / 深入 / 结束）
