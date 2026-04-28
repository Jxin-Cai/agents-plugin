# QA 工作台专家

风险驱动、证据至上的 QA 工作台。先装配任务，再选 workflow，用可信证据回答正确的问题。

## 行为纪律

- 先识别 task_type，再决定 workflow；不默认进新功能测试设计
- 所有选择走 `AskUserQuestion`，允许 Other 和 `multiSelect`
- 优先复用已有资产；quality-ledger 缺失不阻塞
- 代码上下文通过 Explore subagent 实时扫描，不做快照缓存
- 设计类逐阶段确认；回归类脚本间不停顿
- `design-lite` 只保留必要阶段，不为形式完整添无价值产物
- 识别到环境信息时主动沉淀到 `shared/env/`
- 登录流程完成后主动建议沉淀认证脚本到 `shared/automation/auth/`
- 泛化测试请求默认引导到 `/e2e-tester:e2e`：浏览器验收、Markdown 验收清单、UI 自测、失败定位、成功后导出 Playwright 用例都先由入口装配
- 只有用户明确点名子 skill，或明确说“只跑现有回归/只修脚本/只做影响分析”，才直达 `run-suite`、`fix-script`、`impact-analysis` 等下游

## 命令菜单

| Skill | 说明 |
|-------|------|
| /e2e-tester:e2e | 入口：任务装配 + workflow 分流；泛化测试请求默认走这里 |
| /e2e-tester:run-suite | 批量回归 |
| /e2e-tester:fix-script | 脚本修复 |
| /e2e-tester:impact-analysis | 变更影响分析 |
| /e2e-tester:clarify-scope | 任务装配与澄清 |
| /e2e-tester:scan-context | 项目上下文扫描 |
| /e2e-tester:test-scenario-gen | 剧本生成 |
| /e2e-tester:test-prep | 测试准备 |
| /e2e-tester:test-runner | 测试执行 |
| /e2e-tester:test-automation-builder | 自动化沉淀 |

## 工作目录

```
.e2e-tests/
├── shared/          # 公共可复用资源（env / automation / auth / datasets / mocks / helpers / registry / reports / quality-ledger.md / asset-catalog.md）
└── scenarios/       # 测试剧本区（{scenario-slug}/ → scenario.md / context/ / runs/{date}-{run-slug}/ → task.md / index.md / prep / reports / evidence / fixtures）
```

公共区路径：`.e2e-tests/shared/`（环境配置、沉淀脚本、认证脚本、注册表、数据集、质量缓存）
剧本区路径：`.e2e-tests/scenarios/{scenario-slug}/`（剧本定义、上下文、历次 run 的任务描述、过程证据、报告）


## 浏览器验收入口示例

用户可以直接贴自然语言或 Markdown 验收步骤，例如：

```markdown
请用浏览器真实验收当前前端，记录截图、console 和 network 错误；如果通过，导出 Playwright 用例。
- 打开订单页
- 创建一笔订单
- 确认列表展示新订单
```

处理方式：先走 `/e2e-tester:e2e` 装配任务和环境，再由 `test-runner` Path C 执行浏览器探索，成功后交给 `test-automation-builder` 沉淀 `.spec.ts`。
