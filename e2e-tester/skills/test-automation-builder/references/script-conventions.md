# 自动化脚本规范

## 命名

- api-script: `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.test.ts`
- e2e-script: `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.spec.ts`

## JSDoc 元数据（必须）

```typescript
/**
 * @type {api-script | e2e-script}
 * @scenario TS-{NNN}
 * @domain {domain}
 * @task_folder {YYYY-MM-DD}-{task-slug}
 * @title {中文标题}
 * @business_scenario {场景}
 * @cases C1, C2, C3
 * @risk {High | Medium | Low}
 * @persona {role}
 * @covers {feature1}, {feature2}
 * @tags {tag1}, {tag2}
 * @oracle {api, data, side-effect}
 * @prep prep/TP-{NNN}-{slug}.md
 * @task task/task.md
 * @api_endpoints {POST /api/xxx}, {GET /api/yyy}
 * @datasets / @mock_assets / @helpers {paths}
 * @created / @last_updated {YYYY-MM-DD}
 * @automation_confidence {high | medium | low}
 * 限制: {未自动化覆盖的部分}
 */
```

强制字段：`@type`、`@business_scenario`、`@cases`、`@risk`、`@persona`、`@oracle`、`@prep`、`@task`、`@api_endpoints`、`@automation_confidence`、`限制`

## api-script 规则

- 用 `fetch` / HTTP client，禁止 import playwright
- 断言基于 HTTP status + response body
- 状态验证通过查询接口
- `npx tsx` 直接运行
- 需 mock 时用 `shared/helpers/mock-loader`

## e2e-script 规则

- Playwright Test Runner 结构（`test.describe` / `test`）
- 数据准备优先 API（`page.request` / `beforeAll`）
- UI 只用于无 API 替代的操作
- `npx playwright test` 运行

## 断言最低标准

- 必须有 API 层断言（status + body 关键字段）
- 状态流转必须通过查询接口验证
- 异常路径验证错误码和信息
- 多 case 时每个 case 独立断言块
- 不接受：只检查 200 不看 body / 只看页面文本

## Subagent 生成 Prompt 模板

```text
你是自动化测试脚本生成器。
生成类型：{api-script | e2e-script}
可用工具：仅 Read, Write。不读 node_modules/，不执行命令。

【api-script】纯 TS 脚本（.test.ts），fetch 调接口，assert 验证，npx tsx 运行。绝对不用 Playwright。
【e2e-script】Playwright 脚本（.spec.ts），test.describe/test 结构，数据准备用 API，UI 仅用于必须操作。

通用：复用已有 helper/数据集/mock。头部含完整 JSDoc。断言覆盖关键 oracle。每 case 独立。含清理逻辑。

输入：剧本、prep、任务文件、API 调用链摘要、可复用资产
输出：写入 .e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.{test|spec}.ts
```
