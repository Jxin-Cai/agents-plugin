# Product Manager - Claude Code Plugin

产品经理工作台插件，为 Claude Code 提供完整的 PM 工作流能力。从需求发现到 PRD 成文、Story 拆分、指标定义、治理分析、上线复盘，覆盖产品经理日常工作的全部阶段。

## 快速开始

```bash
# 进入产品经理工作台
/pa 做一个用户权限管理的需求

# 直接调用特定技能
/pa 路线图规划
/pa 知识库管理
```

## 核心设计理念

- **路由优先** -- 先判断用户当前要做的 PM 工作类型，再进入对应 SOP
- **渐进加载** -- 澄清阶段后由用户选择本次要做的分析维度，只加载被选中的 SOP
- **状态接续** -- 通过 `meta/workbench-state.md` 记录进度，支持跨会话断点续做
- **用户主导** -- 关键判断交给用户，不替代产品决策；每步确认后才继续

## 插件能力总览

### 工作台入口

| 命令 | 说明 |
|------|------|
| `/pa <描述>` | 产品经理工作台主入口，自动识别工作类型并路由到对应 SOP |

### 需求交付流程（基础路径）

这是最常用的工作流，按顺序经历三个基础阶段：

| 阶段 | 技能 | 职责 | 核心产出 |
|------|------|------|---------|
| 1 | `scan-context` | 扫描项目上下文，提取与需求相关的领域知识 | `domain/context-{日期}.md` |
| 2 | `brainstorm-requirements` | 四视角需求发散 + 三条链路标注 + MECE 检查 | `domain/brainstorm-{日期}.md` |
| 3 | `clarify-requirements` | 逐模块澄清边界/异常/逆向 + P0/P1/P2 标注 + **选择分析维度** | `domain/clarified-{日期}.md` |

### 可选分析维度（维度驱动）

澄清阶段后，用户多选本次要做的分析维度，后续只加载被选中的 SOP：

| 维度标识 | 技能 | 职责 | 核心产出 |
|---------|------|------|---------|
| `prd` | `generate-prd` | 将澄清成果收敛为结构化 PRD（七列功能清单） | `prd/prd-{名称}-{日期}.md` |
| `story` | `story-decompose` | PRD 拆分为 Epic / User Story，INVEST 验证 + Given/When/Then | `stories/stories-{日期}.md` |
| `success-metrics` | `define-success` | 三层指标体系：北极星 + 功能 + 护栏 | `metrics/success-metrics-{日期}.md` |
| `discovery` | `discovery-product` | 问题/证据/假设/实验，判断是否进入交付 | `discovery/discovery-{日期}.md` |
| `enterprise-nfr` | `enterprise-nfr` | 性能/可靠性/安全/审计等非功能需求深挖 | `nfr/nfr-{日期}.md` |
| `governance` | `regulatory-governance` | 行业监管和企业治理要求转化为产品要求 | `governance/governance-{日期}.md` |
| `roadmap` | `portfolio-roadmap` | 机会池整理 + 量化优先级 + Now/Next/Later 路线图 | `.product-manager/portfolio/{日期}-{slug}/` |

### SDD 规格闭环增强

| 能力 | 承载技能 | 职责 | 核心产出 / 状态 |
|------|---------|------|----------------|
| Spec Quality Gate | `generate-prd` | 检查完整性、可测性、一致性、可追溯性、风险透明度 | `prd/spec-quality-gate-{日期}.md`、`quality_gate.status` |
| 可独立交付切片 | `story-decompose` | 检查 Story 是否具备独立价值、独立验收、跨层闭环、依赖与回滚说明 | `slice_status`、Story 切片矩阵 |
| 规格状态机 | `pa` + 各阶段技能 | 维护 draft → approved → in-development → shipped → retired | `meta/workbench-state.md` |
| UAT 验收包 | `story-decompose` | 将 Story、指标、NFR、治理要求转成 UAT 验收清单 | `stories/uat-pack-{日期}.md`、`uat_status` |
| 规格归档与知识回流 | `post-launch-review` + `product-knowledge archive-spec` | 从复盘提取可复用决策、术语、模式、产品约束 | `knowledge_sync.archive`、`spec_state: retired` |

### 闭环与知识沉淀

| 技能 | 职责 | 核心产出 |
|------|------|---------|
| `post-launch-review` | 上线复盘：功能交付评估、指标对比、决策审计、知识回流候选提取 | `review/review-{日期}.md` |
| `product-knowledge` | 知识库管理：决策日志、领域术语、需求模式、产品上下文、规格归档 | `.product-manager/intelligence/` |


## 典型工作流

### 场景 1：标准需求交付

```
/pa 做一个导出报表的功能
  -> scan-context（扫描项目）
  -> brainstorm-requirements（四视角发散）
  -> clarify-requirements（逐项澄清 + 选维度：prd, story）
  -> generate-prd（生成 PRD）
  -> story-decompose（拆 Story）
```

### 场景 2：先验证再交付

```
/pa 我们想做一个 AI 推荐功能，但不确定用户是否需要
  -> 路由到 discovery-product
  -> 验证结论：进入交付
  -> clarify-requirements + generate-prd
```

### 场景 3：只做治理分析

```
/pa 这个功能涉及 PCI-DSS 合规
  -> 路由到 regulatory-governance
  -> 输出治理要求矩阵 + 分阶段路线图
```

### 场景 4：路线图规划

```
/pa 下季度路线图
  -> 路由到 portfolio-roadmap
  -> 机会池 -> RICE 评估 -> Now/Next/Later
```

### 场景 5：上线复盘

```
/pa 上线复盘
  -> 路由到 post-launch-review
  -> PRD vs 实际对比 -> 决策审计 -> 模式沉淀到知识库
```

### 场景 6：SDD 规格闭环

```
/pa 做一个高风险支付风控需求
  -> clarify-requirements（澄清并选择 prd/story）
  -> generate-prd（生成 PRD + Spec Quality Gate）
  -> story-decompose（独立交付切片 + UAT 验收包）
  -> req-publish（质量门 / 切片 / UAT 守卫通过后发布）
  -> post-launch-review（复盘并提取知识回流候选）
  -> product-knowledge archive-spec（归档并写入知识库）
```

## 目录结构

### 插件结构

```
product-manager/
  .claude-plugin/
    plugin.json              # 插件元数据
  commands/
    pa.md                    # /pa 命令入口
  hooks/
    hooks.json               # Hook 配置
    session-start.sh         # 会话启动：展示知识库状态和需求周期
  skills/
    pa/                      # 工作台主路由
    scan-context/            # 上下文扫描
    brainstorm-requirements/ # 需求风暴
    clarify-requirements/    # 需求澄清
    generate-prd/            # PRD 生成
    story-decompose/         # Story 拆分
    define-success/          # 成功指标
    discovery-product/       # 发现式产品管理
    enterprise-nfr/          # 企业级 NFR
    regulatory-governance/   # 监管与治理
    portfolio-roadmap/       # 路线图
    post-launch-review/      # 上线复盘
    product-knowledge/       # 知识库管理
```

### 工作产物目录（运行时生成）

```
.product-manager/requirements/{YYYY-MM-DD}-{slug}/   # 需求交付
  raw/                                # 原始需求文档
  domain/                             # 领域知识、风暴、澄清产出
  discovery/                          # 发现式验证产出
  prd/                                # PRD 文档
  stories/                            # Story 清单与 UAT 验收包
  metrics/                            # 成功指标
  nfr/                                # 非功能需求
  governance/                         # 治理分析
  review/                             # 上线复盘
  meta/
    workbench-state.md                # 状态文件（进度、已选维度）

.product-manager/portfolio/{YYYY-MM-DD}-{slug}/      # 路线图工作
  opportunities/                      # 机会池
  priority/                           # 优先级评估
  roadmap/                            # 路线图
  meta/

.product-manager/discovery/{YYYY-MM-DD}-{slug}/      # 独立 discovery

.product-manager/intelligence/               # 产品知识库
  product-context.md                  # 产品上下文
  decision-journal.md                 # 决策日志
  domain-glossary.md                  # 领域术语
  patterns.md                         # 需求模式
  changelog.md                        # 变更记录
```

## 状态管理

每个需求周期通过 `meta/workbench-state.md` 管理状态：

| 字段 | 说明 |
|------|------|
| `workflow_mode` | 工作模式（requirement-delivery 等） |
| `selected_dimensions` | 用户选择的分析维度 |
| `completed_steps` | 已完成的步骤 |
| `next_recommended_step` | 推荐的下一步 |
| `artifact_paths` | 各阶段产物路径 |
| `spec_state` | 规格状态机：draft / approved / in-development / shipped / retired |
| `quality_gate` | Spec Quality Gate 状态、报告路径和失败项 |
| `slice_status` | Story 是否达到独立交付切片标准 |
| `uat_status` | UAT 验收包状态：pending / ready / waived |
| `knowledge_sync` | 知识库同步状态（可选） |

状态文件使后续技能可以：
- 判断当前进度，推荐下一步
- 跨会话断点续做
- 只展示与已选维度相关的后续操作

## 产品方法论

插件内置的产品分析方法论包括：

- **三条链路** -- 正向 + 异常 + 逆向，每个功能点都要覆盖
- **七列功能清单** -- 功能点 / 正向 / 异常 / 逆向 / 边界 / 优先级
- **四视角发散** -- 用户 / 流程 / 数据 / 集成
- **INVEST 原则** -- Story 质量验证
- **Given/When/Then** -- 验收标准格式
- **三层指标** -- 北极星 + 功能 + 护栏
- **RICE/WSJF** -- 优先级量化框架
- **积木式构建** -- 功能独立、可组合、可拆卸
- **领域复杂度感知** -- 不同行业的强制性需求维度
