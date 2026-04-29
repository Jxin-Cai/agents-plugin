# 自动化脚本规范

## 命名

- api-script: `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.test.ts`
- e2e-script: `.e2e-tests/shared/automation/{domain}/ts-{nnn}-{slug}.spec.ts`
- auth-script: `.e2e-tests/shared/automation/auth/login-{env}.test.ts`

## JSDoc 元数据（必须）

| 字段 | 必填 | 说明 |
|------|------|------|
| @type | ✓ | api-script / e2e-script / auth-script |
| @scenario | ✓ | TS-{NNN} |
| @domain | | 业务域 |
| @scenario_slug | | 场景 slug |
| @title | | 中文标题 |
| @business_scenario | ✓ | 场景描述 |
| @cases | ✓ | C1, C2, C3 |
| @risk | ✓ | High / Medium / Low |
| @persona | ✓ | 角色 |
| @covers | | feature 列表 |
| @tags | | 标签列表 |
| @oracle | ✓ | api, data, side-effect |
| @prep | ✓ | 准备方案路径 |
| @task | ✓ | 任务文件路径 |
| @api_endpoints | ✓ | POST /api/xxx, GET /api/yyy |
| @acceptance_steps | ✓ | AS-001, AS-002 |
| @source_run | ✓ | 来源 run 路径 |
| @source_report | ✓ | 来源报告路径 |
| @source_evidence | ✓ | 来源证据路径 |
| @datasets / @mock_assets / @helpers | | 资产路径 |
| @created / @last_updated | | 日期 |
| @automation_confidence | ✓ | high / medium / low |
| 限制 | ✓ | 未自动化覆盖的部分 |

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

> Subagent prompt 和 Path C 导出门禁见 script-subagent-prompt.md。
