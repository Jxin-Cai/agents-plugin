# Subagent 生成 Prompt 与导出门禁

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
