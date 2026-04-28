# 自动化脚本规范

## 命名

- api-script: `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.test.ts`
- e2e-script: `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.spec.ts`
- auth-script: `.e2e-tests/shared/automation/auth/login-{env}.test.ts`

## JSDoc 元数据（必须）

```typescript
/**
 * @type {api-script | e2e-script | auth-script}
 * @scenario TS-{NNN}
 * @domain {domain}
 * @scenario_slug {scenario-slug}
 * @title {中文标题}
 * @business_scenario {场景}
 * @cases C1, C2, C3
 * @risk {High | Medium | Low}
 * @persona {role}
 * @covers {feature1}, {feature2}
 * @tags {tag1}, {tag2}
 * @oracle {api, data, side-effect}
 * @prep runs/{date}-{run-slug}/prep/TP-{NNN}-{slug}.md
 * @task runs/{date}-{run-slug}/task.md
 * @api_endpoints {POST /api/xxx}, {GET /api/yyy}
 * @acceptance_steps AS-001, AS-002
 * @source_run .e2e-tests/scenarios/{scenario}/runs/{run}
 * @source_report runs/{date}-{run-slug}/reports/TS-{NNN}-run-{RRR}.md
 * @source_evidence runs/{date}-{run-slug}/evidence/{case-id}/evidence-manifest.md
 * @datasets / @mock_assets / @helpers {paths}
 * @created / @last_updated {YYYY-MM-DD}
 * @automation_confidence {high | medium | low}
 * 限制: {未自动化覆盖的部分}
 */
```

强制字段：`@type`、`@business_scenario`、`@cases`、`@risk`、`@persona`、`@oracle`、`@prep`、`@task`、`@api_endpoints`、`@acceptance_steps`、`@source_run`、`@source_report`、`@source_evidence`、`@automation_confidence`、`限制`

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
- selector 优先级：testid / role+name / label / stable text；避免 CSS 层级和动态 class
- 从 Path C 导出时保留 `test.step("AS-001 ...")` 或等价结构，便于追溯验收步骤
- 登录优先复用 `shared/automation/auth/login-{env}.test.ts` 或 Playwright storage state，不在每个 spec 内重复硬编码
- `npx playwright test` 运行

## auth-script 规则

- 传入账号密码（通过环境变量），返回 token/cookie
- 可被其他脚本 import 使用
- 应 export 一个 `login(env, username, password)` 函数
- 存放于 `shared/automation/auth/login-{env}.test.ts`

## 断言最低标准

- 必须有 API 层断言（status + body 关键字段）
- 状态流转必须通过查询接口验证
- 异常路径验证错误码和信息
- 多 case 时每个 case 独立断言块
- 不接受：只检查 200 不看 body / 只看页面文本 / 只复刻探索点击而没有 oracle / 使用一次性 DOM 层级 selector

## Subagent 生成 Prompt 模板

```text
你是自动化测试脚本生成器。
生成类型：{api-script | e2e-script | auth-script}
可用工具：仅 Read, Write。不读 node_modules/，不执行命令。

【api-script】纯 TS 脚本（.test.ts），fetch 调接口，assert 验证，npx tsx 运行。绝对不用 Playwright。
【e2e-script】Playwright 脚本（.spec.ts），test.describe/test 结构，数据准备用 API，UI 仅用于必须操作。
【auth-script】认证脚本（.test.ts），export login 函数，传入账号密码返回 token/cookie。

通用：复用已有 helper/数据集/mock。头部含完整 JSDoc。断言覆盖关键 oracle。每 case 独立。含清理逻辑。

输入：剧本、Step Mapping、prep、任务文件、报告、evidence manifest、console/network artifact、API 调用链摘要、可复用资产
输出：写入对应路径
```


## Path C 导出 gate

只有同时满足以下条件，才把成功探索导出为 `.spec.ts`：

- 关键 oracle 已在报告中判定，且证据文件可追溯。
- 选择器稳定，能用 testid、role、label 或稳定文本表达。
- 登录、前置数据、重置和清理策略可复跑。
- network/API 证据能解释关键业务副作用。
- console 错误已分类，不存在未解释的业务错误。

不满足时更新 report/index/registry 的 blocked reason，不生成脆弱脚本。
