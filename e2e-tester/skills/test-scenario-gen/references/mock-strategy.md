# Mock 策略指南

## 策略决策

| 依赖类型 | 策略 | 理由 |
|---------|------|------|
| 被测核心服务 | real | 必须验证真实行为 |
| 第三方支付/短信 | mock | 不可控，有资金/发送风险 |
| 内部服务（稳定） | real | 验证真实集成 |
| 内部服务（不稳定） | mock | 避免环境干扰 |
| 需特定数据状态 | fixture | 预制数据更可靠 |

> 涉及契约校验、故障注入或有状态依赖时，读取 `references/mock-strategy-advanced.md`。

## Mock 配置格式

路径：`.e2e-tests/{domain}/fixtures/mocks/{service}.mock.yaml`

```yaml
service: {name}
description: {说明}
base_url: {原始地址}
default_response: { status: 200, body: { message: "mock default" } }
endpoints:
  - name: {规则名}
    path: /v1/{resource}     # 支持 {param} 占位
    method: POST
    request:                 # 可选匹配条件
      body: { amount: { lte: 100000 } }
    response:
      status: 200
      body: { id: "mock_001", status: "succeeded" }
      delay_ms: 0            # 模拟慢接口
```

匹配条件：path、method、request.body、request.headers、request.query
响应模板：status、body（支持 `{{ request.* }}` 引用）、headers、delay_ms

## 运行时加载方式

| 场景 | 方式 |
|------|------|
| api-script | `_shared/helpers/mock-loader.ts`（脚本内 mock helper） |
| Playwright 探索 | `page.route()` 网络拦截 |
| 多服务联调 | 外部 Mock Server |
| 1-2 个端点 | 脚本内硬编码 |

mock-loader 不存在时由 `test-automation-builder` subagent 一并生成，登记到 `asset-catalog.md`。

## 剧本中声明

```yaml
dependencies:
  - service: payment-gateway
    strategy: mock
    mock_config: fixtures/mocks/payment-gateway.mock.yaml
```
