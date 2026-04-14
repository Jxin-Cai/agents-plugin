# E2E-Tester Plugin

风险驱动、证据至上的 QA 工作台。先装配任务，再选 workflow，用可信证据回答正确的问题。

## 核心能力

- **多场景 QA 支持** — 新功能验收、发布验证、回归测试、影响分析、缺陷复现、专项验证、脚本维护
- **智能 Workflow 分流** — 根据任务意图自动匹配最合适的工作流程，不把所有事情都拖进完整设计模式
- **BDD 剧本设计** — 业务场景 x Case x Oracle 矩阵的结构化测试设计
- **三路径执行** — 已有脚本自动化 / 实时生成后执行 / Playwright 探索式验证
- **资产沉淀与复用** — 注册表管理测试脚本元数据，支持跨剧本资产复用
- **断点恢复** — 基于文件产物自动推断接续点，支持任务中断后恢复

## 快速开始

### 入口命令

```
/e2e <被测功能、发布范围、缺陷现象或回归目标>
```

### 常用示例

| 场景 | 命令 |
|------|------|
| 新功能测试 | `/e2e 帮我测新的支付流程` |
| 发布前验证 | `/e2e 今晚发版前做验证` |
| 批量回归 | `/e2e 跑回归` 或 `/e2e-tester:run-suite smoke` |
| 缺陷复现 | `/e2e 复现订单重复提交问题` |
| 影响分析 | `/e2e 这次改动影响什么` 或 `/e2e-tester:impact-analysis` |
| 修复脚本 | `/e2e fix ts-001` 或 `/e2e-tester:fix-script ts-001` |
| 沉淀脚本 | `/e2e-tester:test-automation-builder` |

## Workflow 体系

插件支持 7 种 Workflow，根据任务意图自动分流：

| Workflow | 适用场景 | 执行链路 |
|----------|---------|---------| 
| `design-full` | 新功能、复杂验证 | 装配 → 扫描 → 剧本 → 准备 → 执行 → 沉淀 |
| `design-lite` | 专项验证（权限/数据/集成） | 只保留必要阶段的最小可信设计链 |
| `release-gate` | 发布前验证 | 装配 → 影响分析 → 回归 → 补充验证 → GO/NO-GO |
| `regression-batch` | 批量回归 | 直接执行已有脚本 |
| `impact-first` | 变更影响分析 | 分析影响 → 推导回归范围 |
| `repro-loop` | 缺陷复现 | 最小准备 → 探索执行 → 证据链 |
| `script-maintenance` | 脚本修复/沉淀 | 诊断 → 修复 → 验证 → 更新注册表 |

## Skill 清单

| Skill | 说明 | 直接可用 |
|-------|------|---------| 
| `e2e` | 入口：任务装配 + workflow 分流 | `/e2e-tester:e2e` |
| `clarify-scope` | 任务装配与澄清，识别工作类型/目标/风险/边界 | `/e2e-tester:clarify-scope` |
| `scan-context` | 项目上下文扫描（通过 Explore subagent 直读源码） | `/e2e-tester:scan-context` |
| `test-scenario-gen` | BDD 剧本生成 | `/e2e-tester:test-scenario-gen` |
| `test-prep` | 测试准备方案 + readiness gate | `/e2e-tester:test-prep` |
| `test-runner` | 测试执行（A/B/C 三路径）+ 质量报告 | `/e2e-tester:test-runner` |
| `test-automation-builder` | 自动化脚本沉淀（通过 subagent 生成） | `/e2e-tester:test-automation-builder` |
| `run-suite` | 批量回归执行 | `/e2e-tester:run-suite` |
| `fix-script` | 脚本诊断与修复 | `/e2e-tester:fix-script` |
| `impact-analysis` | 变更影响分析 + 回归推导 | `/e2e-tester:impact-analysis` |

## 工作目录结构

```
.e2e-tests/
├── shared/                                  # 公共可复用资源区（跨剧本复用）
│   ├── env/                                 # 环境配置（{env}.yaml）
│   ├── automation/                          # 沉淀的自动化脚本
│   │   ├── auth/                            # 认证脚本（登录、获取 token）
│   │   └── {domain}/                        # 按业务域分（ts-{nnn}-{slug}.test.ts / .spec.ts）
│   ├── datasets/                            # 共享测试数据集
│   ├── mocks/                               # 共享 Mock 配置
│   ├── helpers/                             # 共享 Helper
│   ├── registry/                            # 脚本注册表
│   │   ├── index.yaml                       # 全局索引
│   │   ├── {domain}.yaml                    # 域级注册
│   │   └── suites.yaml                      # 套件定义
│   ├── reports/                             # 全局回归报告
│   ├── quality-ledger.md                    # 质量经验缓存
│   └── asset-catalog.md                     # 资产总目录
│
└── scenarios/                               # 测试剧本区（按业务场景组织）
    └── {scenario-slug}/                     # 某个业务场景
        ├── scenario.md                      # 剧本定义（稳定的 case 池）
        ├── context/                         # 上下文扫描（场景级，跨 run 共享）
        └── runs/                            # 历次执行
            └── {YYYY-MM-DD}-{run-slug}/     # 某次测试任务
                ├── task.md                  # 本次任务完整需求描述
                ├── index.md                 # 任务状态（唯一状态文件）
                ├── prep/                    # 准备方案（TP-{NNN}-{slug}.md）
                ├── evidence/                # 过程证据
                │   └── {case-id}/           # 按 case 组织
                │       ├── screenshots/     # 截图
                │       ├── videos/          # 录屏
                │       ├── api/             # 接口交互记录
                │       ├── snapshots/       # 可访问性快照（strict）
                │       └── evidence-manifest.md
                ├── reports/                 # 执行报告
                └── fixtures/                # 本次专用数据/Mock
```

### 两大区域设计原则

| 区域 | 目录 | 内容 | 生命周期 |
|------|------|------|---------| 
| **公共区** | `shared/` | 环境配置、沉淀脚本（含认证脚本）、注册表、数据集、质量缓存 | 持久，跨剧本复用 |
| **剧本区** | `scenarios/{slug}/` | 剧本定义、上下文、历次执行的过程证据和报告 | 剧本持久，run 按执行增量 |

### 概念模型

| 概念 | 说明 |
|------|------|
| **Scenario（剧本）** | 稳定的业务场景定义，包含完整的 case 池。跨 run 共享，随业务演进补充 case |
| **Run（执行）** | 每次具体的测试任务。选择剧本中的 case 子集执行，有独立的需求描述和过程记录 |
| **Context（上下文）** | 场景级的代码/技术上下文扫描结果，跨 run 复用，变动时更新 |
| **认证脚本** | 沉淀到 `shared/automation/auth/`，提供 login → token/cookie 能力，供所有剧本复用 |

## 核心概念

### 任务装配

每次 QA 工作从"装配"开始——识别任务类型、目标、风险、边界、交付物，然后选择合适的 workflow。不默认把所有事情都拖进完整的六阶段测试设计。

### Oracle 模型

剧本中的每个 Case 通过多层 Oracle 验证：

| Oracle 类型 | 说明 |
|------------|------|
| UI | 页面文案、状态、可见性 |
| API | 接口状态码 + 响应体关键字段 |
| Data | 数据库/查询接口验证状态流转 |
| Side Effect | 副作用（通知、日志、外部调用） |
| Async | 异步操作的最终一致性 |
| Idempotency | 重复操作的幂等性 |

关键原则：**只有 UI 信号没有业务结果信号 = 不可信**。

### 三路径执行

| 路径 | 条件 | 说明 |
|------|------|------|
| A: 自动化 | 已有脚本匹配 | 直接执行注册表中的脚本 |
| B: 生成后执行 | Oracle 可机械验证 + 准备完整 | 通过 subagent 实时生成脚本再执行 |
| C: Playwright 探索 | 其他情况 | 逐 case 手动探索，捕获 API 调用链 |

### 注册表

每个自动化脚本在注册表中有完整元数据（路径、覆盖场景、风险等级、API 端点、源码路径等）。`impact-analysis` 通过注册表元数据推导变更影响，`run-suite` 通过注册表定位脚本。

### Quality Ledger

跨任务的质量经验缓存，记录：失败模式、时序基线、环境陷阱、依赖稳定性、Flaky 治理。存在时加速决策，缺失不阻塞流程。

### 证据采集分级

执行新测试剧本时，引导用户选择证据采集级别（`evidence_level`），不同级别决定截图密度、API 记录粒度和辅助日志采集范围：

| 级别 | 截图 | API 记录 | 辅助采集 | 适用场景 |
|------|------|---------|---------|---------| 
| light | Given + Then（每 case 2 张） | 关键业务 API 出入参对 | 无 | 快速验证、design-lite |
| standard | 每步截图 | 全量 API 调用链 | 错误级别控制台日志 | 一般场景（默认） |
| strict | 每原子操作截图 | 全量 API 调用链 | 可访问性快照 + 全量控制台日志 | 发布验证、合规审计 |

证据文件存储在 `scenarios/{slug}/runs/{date}-{slug}/evidence/{case-id}/` 下，standard/strict 模式自动生成 `evidence-manifest.md` 索引所有证据文件，供测试报告结构化引用。

### 第三方脚本屏蔽

Playwright 探索执行时自动屏蔽已知的第三方统计/监控脚本（piwik、GA、Sentry、Hotjar 等），防止干扰测试。可通过环境配置 `blocked_scripts` 自定义屏蔽列表。

## 脚本类型

| 类型 | 文件后缀 | 存放路径 | 执行方式 | 适用场景 |
|------|---------|---------|---------|---------| 
| api-script | `.test.ts` | `shared/automation/{domain}/` | `npx tsx` | 核心操作有 API + 状态可查询 |
| e2e-script | `.spec.ts` | `shared/automation/{domain}/` | `npx playwright test` | 部分操作必须通过 UI 完成 |
| auth-script | `.test.ts` | `shared/automation/auth/` | `npx tsx` | 登录获取 token/cookie |

## 行为纪律

- 所有选择走 `AskUserQuestion`，设计类逐阶段确认
- 每阶段从文件读上下文，不依赖对话记忆
- 重型任务（上下文扫描、脚本生成）走 subagent
- 优先复用已有资产
- 无准备不执行，无关键证据不判 PASS
- 识别到环境信息（URL、账号、认证方式）时主动沉淀到 `shared/env/`
- 登录流程执行后主动建议沉淀认证脚本到 `shared/automation/auth/`
