# 注册表与套件规范

定义自动化脚本注册表（registry）、命名套件（suites）和资产目录（asset-catalog）的结构和维护规则。

---

## 全局索引 — `registry/index.yaml`

```yaml
version: 1
last_updated: {ISO 8601}
domains:
  {domain}:
    file: registry/{domain}.yaml
    script_count: {N}
    last_updated: {ISO 8601}
```

### 维护规则
- 每次脚本新增/删除/更新时同步更新 `last_updated` 和 `script_count`
- `domains` 枚举所有有脚本的域
- 读取时按需加载域注册表，不一次性加载所有域

---

## 域注册表 — `registry/{domain}.yaml`

```yaml
domain: {domain}
scripts:
  ts-{nnn}-{slug}:
    type: api-script | e2e-script
    path: .e2e-tests/{domain}/automation/ts-{nnn}-{slug}.{test|spec}.ts
    scenario: TS-{NNN}
    business_scenario: {中文描述}
    risk_level: High | Medium | Low
    tags: [{tag1}, {tag2}]
    covers: [{feature1}, {feature2}]
    api_endpoints: [{POST /api/xxx}, {GET /api/yyy}]
    source_paths: [{src/modules/xxx/**/*.ts}, {src/services/yyy/**/*.ts}]
    persona: {role}
    last_passed: {YYYY-MM-DD} | null
    last_failed: {YYYY-MM-DD} | null
    fail_count: 0
    stale: false
    suites: [{smoke}, {regression}]
    automation_confidence: high | medium | low
    created: {YYYY-MM-DD}
    last_updated: {YYYY-MM-DD}
```

### 字段说明

| 字段 | 必须 | 说明 |
|------|------|------|
| `type` | 是 | `api-script`（`.test.ts`）或 `e2e-script`（`.spec.ts`） |
| `path` | 是 | 脚本文件路径 |
| `scenario` | 是 | 对应剧本编号 |
| `business_scenario` | 是 | 一句话业务场景描述 |
| `risk_level` | 是 | 业务风险等级 |
| `tags` | 否 | 用于模糊匹配和批量过滤 |
| `covers` | 否 | 覆盖的功能点，用于影响分析 |
| `api_endpoints` | 是 | 脚本调用的 API 端点列表 |
| `source_paths` | 是 | 业务源码路径 glob，用于 git diff 影响分析 |
| `persona` | 是 | 测试角色 |
| `last_passed` | 否 | 最后通过日期，由 run-suite 更新 |
| `last_failed` | 否 | 最后失败日期，由 run-suite 更新 |
| `fail_count` | 否 | 连续失败次数，PASS 时归零 |
| `stale` | 否 | 标记过期脚本 |
| `suites` | 否 | 所属命名套件 |
| `automation_confidence` | 是 | 自动化信心等级 |

### 更新时机

| 事件 | 更新字段 |
|------|---------|
| 脚本新建（test-automation-builder） | 全部字段初始化 |
| 回归通过（run-suite） | `last_passed` → today, `fail_count` → 0, `stale` → false |
| 回归失败（run-suite） | `last_failed` → today, `fail_count` += 1 |
| 脚本修复（fix-script） | `last_passed` → today, `fail_count` → 0, `last_updated` → today |

---

## 命名套件 — `registry/suites.yaml`

```yaml
suites:
  smoke:
    description: 核心业务流程快速检查
    scripts: [ts-001, ts-003, ts-007]    # 显式列表（优先级最高）

  regression:
    description: 完整回归，排除过期脚本
    filter:                               # 动态过滤
      stale: false

  payment:
    description: 支付相关全部测试
    filter:
      tags: [payment]

  high-risk:
    description: 高风险脚本
    filter:
      risk_level: High
```

### 解析规则

1. `scripts` 存在 → 使用显式列表
2. `filter` 存在 → 遍历所有域注册表匹配
3. 两者同时存在 → `scripts` 优先
4. 过滤器支持：`risk_level`、`tags`、`covers`、`domain`、`type`、`stale`
5. 多个过滤条件为 AND 关系

---

## 资产目录 — `asset-catalog.md`

`.e2e-tests/asset-catalog.md` 是跨 domain 资产发现的主入口。

```markdown
# 资产目录

## 共享数据集
| 名称 | 路径 | 适用场景 | 创建日期 |
|------|------|---------|----------|

## 共享 Mock
| 名称 | 路径 | 模拟对象 | 创建日期 |
|------|------|---------|----------|

## 共享 Helper
| 名称 | 路径 | 功能 | 创建日期 |
|------|------|------|----------|

## 可复用脚本（跨域参考）
| 脚本 | 域 | 业务场景 | 可复用点 |
|------|-----|---------|----------|
```

### 分片策略

当资产目录超过 200 行时：
- 顶层 `asset-catalog.md` 只保留每个区块前 10 条 + 总数统计
- 完整内容移到 `_shared/{category}/README.md`
- 查询时先读顶层索引，按需读取分片

---

## 剧本与脚本的关系

> **剧本是设计阶段的中间产物，脚本 JSDoc 是活规格。**

- 剧本（`scenarios/TS-*.md`）在设计模式 Stage 3 中用于与用户对齐测试策略
- 脚本生成后，JSDoc 元数据承载了剧本 80% 的信息
- **回归模式不要求剧本存在**，不检查剧本-脚本同步
- 需要理解脚本意图时，优先读 JSDoc；只有追溯原始设计决策时才读剧本
