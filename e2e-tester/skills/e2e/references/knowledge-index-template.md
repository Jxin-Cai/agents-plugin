# Knowledge Index 模板

`.e2e-tests/shared/knowledge-index.md` — 全局知识快速索引，供各 skill 在入口阶段快速定位可复用资产。

## 创建时机

- SessionStart hook 检测到 `.e2e-tests/` 存在但 `knowledge-index.md` 不存在时，按此模板创建
- test-runner / test-automation-builder / scan-context 完成时追加/更新条目

## 结构

```markdown
# Knowledge Index

> 自动维护，各 skill 执行后回写。最后更新: {YYYY-MM-DD HH:mm}

## 环境配置

| 环境名 | 文件路径 | base_url | 认证方式 | 状态 |
|--------|---------|----------|---------|------|

## 自动化脚本

| ID | 类型 | 覆盖场景 | 文件路径 | 可靠度 | 最后执行 | 结果 |
|----|------|---------|---------|--------|---------|------|

## 认证脚本

| 环境 | 文件路径 | 认证方式 | 返回物 | 最后验证 |
|------|---------|---------|--------|---------|

## 活跃剧本

| scenario-slug | 描述 | 最后 run | 状态 | case 数 |
|--------------|------|---------|------|---------|

## 已知陷阱（Top 5 Active）

| ID | 类型 | 摘要 | 涉及服务 | 规避方式 |
|----|------|------|---------|---------|

## 项目技术栈

| 维度 | 值 |
|------|---|
| 前端框架 | |
| 后端框架 | |
| 测试框架 | |
| 包管理器 | |
| 部署方式 | |
```

## 读取规则

- **e2e 入口（Step 0）**：读取全部，用于自动推断和资产匹配
- **test-runner（阶段 1）**：读取「自动化脚本」「认证脚本」「环境配置」做路径决策
- **test-automation-builder（Step 1）**：读取「自动化脚本」检查重复
- **scan-context**：读取「项目技术栈」判断是否需要重新扫描
- **quick-run**：读取「环境配置」自动选择环境

## 回写规则

- **test-runner 阶段 4.5**：更新「活跃剧本」「已知陷阱」
- **test-automation-builder Step 5**：更新「自动化脚本」「认证脚本」
- **scan-context**：更新「项目技术栈」
- **e2e 入口 Step 1**：更新「活跃剧本」（创建新 run 时）
- **session-start hook**：不写入，只读取摘要展示

## 容量控制

- 每表最多 20 行；超过时保留最近活跃/最高优先级条目
- 「已知陷阱」只保留 Top 5 Active，resolved 条目移除（详见 quality-ledger）
- 脚本表按 automation_confidence DESC 排序
