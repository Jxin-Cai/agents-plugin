---
name: pa
description: 产品经理工作台——识别当前工作类型并进入对应 SOP；需求型工作支持分析维度选择与渐进加载
argument-hint: "<当前想做的产品工作或需求描述>"
---

# 产品经理工作台

用户传入的参数：`$ARGUMENTS`

先别急着进流程。产品经理一天会做很多种事：有时是在推进一个需求，有时是在排路线图，有时是在做 discovery、补治理、补 NFR，或者只是回头复盘。你先判断用户**此刻要完成的工作**，再带他进入对应 SOP。

---

## 加载引用

使用 Read 工具加载以下引用文件，严格遵守其中规则：

- `references/analysis-dimensions.md` — 需求型工作的分析维度与渐进加载规则
- `references/po-agent.md` — 工作台总原则与行为纪律

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 只专注产品经理领域，不主动做跨职能 handoff 设计
- ✅ 先识别当前工作类型，再进入对应 SOP
- ✅ 如果用户意图不明确，使用 `AskUserQuestion` 让用户选择
- ✅ 需求型工作中，澄清阶段后必须让用户多选分析维度
- 🚫 不默认跑完整条需求 SOP
- 🚫 不因为用户提了一个需求，就自动生成 Story、指标、治理、NFR、路线图全部产物
- ⏸️ 每个阶段完成后停下来，等用户确认是否继续

---

## Step 1: 路由当前工作类型

根据 `$ARGUMENTS` 判断工作类型：

- 明确是”需求分析 / PRD / 功能拆解 / 做一个需求” → **需求交付模式**
- 明确是”路线图 / 优先级 / 机会池 / 组合管理” → 调用 `/portfolio-roadmap`
- 明确是”discovery / 问题验证 / 假设 / 实验 / 用户研究” → 调用 `/discovery-product`
- 明确是”监管 / 合规 / 治理 / 审计要求” → 调用 `/regulatory-governance`
- 明确是”企业级 NFR / 性能 / SLA / 安全 / 审计 / 可观测” → 调用 `/enterprise-nfr`
- 明确是”上线复盘 / 回顾结果 / 提取模式” → 调用 `/post-launch-review`
- 明确是”知识库 / 决策 / 术语 / 模式管理” → 调用 `/product-knowledge`
- 明确是”需求卡操作 / issue 查询 / 状态变更 / 搜索 issue / 评论 issue / 附件上传 / 配置需求平台”，或输入为 issue ID 格式（如 `PROJ-123`、`#42`） → 调用 `/req`

如果无法唯一判断：
- 使用 `AskUserQuestion` 让用户从以下选项中选择：
  - 需求交付（推荐）
  - 需求平台操作（查看/搜索/评论/状态变更 issue）
  - 产品组合 / 路线图
  - 发现式产品管理
  - 监管 / 企业治理
  - 企业级 NFR
  - 上线复盘
  - 知识库管理

**⏸️ 等待用户选择。**

---

## Step 2: 需求交付模式

如果用户进入需求交付模式，执行以下流程。

### 2.1 初始化或恢复需求目录

1. 从 `$ARGUMENTS` 提取需求描述，生成简短英文 slug（2-4 个词，用连字符连接）
2. 使用 `AskUserQuestion` 让用户确认 slug
3. 创建或恢复需求目录：`_requirements/{当前日期}-{slug}/`
4. 确保子目录存在：
   - `raw/`
   - `domain/`
   - `discovery/`
   - `prd/`
   - `stories/`
   - `metrics/`
   - `nfr/`
   - `governance/`
   - `review/`
   - `meta/`
5. 初始化或恢复 `meta/workbench-state.md`

状态文件至少包含：
- `workflow_mode: requirement-delivery`
- `slug`
- `requirement_dir`
- `selected_dimensions: []`
- `completed_steps: []`
- `next_recommended_step`
- `artifact_paths`

### 2.2 接续判断

根据 `meta/workbench-state.md` 和实际文件产物判断当前进度：

- 没有 `domain/context-*.md` → 推荐先执行 `/scan-context`
- 有 context 但没有 `brainstorm-*.md` → 推荐 `/brainstorm-requirements`
- 有 brainstorm 但没有 `clarified-*.md` → 推荐 `/clarify-requirements`
- 有 clarified 且 `selected_dimensions` 为空 → 回到 `/clarify-requirements` 补做维度选择
- 有 `selected_dimensions` → 只推荐对应维度的下一步

如果已有产物，先向用户展示接续状态，再问：
- 从推荐阶段继续（推荐）
- 回到更早阶段重做
- 退出工作台

**⏸️ 等待用户选择。**

### 2.3 基础需求路径

需求交付的基础路径是：
1. `/scan-context`
2. `/brainstorm-requirements`
3. `/clarify-requirements`

其中：
- `scan-context` 负责上下文、领域、边界和复杂度识别
- `brainstorm-requirements` 负责发散用户/流程/数据/集成视角
- `clarify-requirements` 负责三条链路、边界、优先级，并让用户多选分析维度

### 2.4 维度驱动的后续 SOP

`clarify-requirements` 完成后，读取 `selected_dimensions`，只展示相应下一步：

- 选了 `discovery` → `/discovery-product`
- 选了 `enterprise-nfr` → `/enterprise-nfr`
- 选了 `governance` → `/regulatory-governance`
- 选了 `prd` → `/generate-prd`
- 选了 `story` → `/story-decompose`（通常在 PRD 后）
- 选了 `success-metrics` → `/define-success`
- 选了 `roadmap` → `/portfolio-roadmap`

推荐顺序：
1. `discovery / enterprise-nfr / governance`（如已选择）
2. `prd`
3. `story / success-metrics`
4. `roadmap`

每完成一个 SOP：
- 更新 `meta/workbench-state.md` 的 `completed_steps`、`next_recommended_step`、`artifact_paths`
- 向用户展示当前已完成维度和剩余可选维度
- 使用 `AskUserQuestion` 询问是否继续下一步

**⏸️ 每步都要等待用户确认。**

---

## Step 3: 工作完成后的建议

当本次已选择的维度全部完成时：

向用户展示：
- 已完成的分析维度
- 主要产物文件路径
- 仍未做但可后补的维度（如果有）
- 知识库是否需要更新

用 `AskUserQuestion` 提供以下选项：
- 继续补做其他分析维度
- 进入上线复盘
- 管理知识库
- 结束本次工作

**⏸️ 停下来等待用户选择。**

---

## 成功标准

### ✅ 成功
- 能先识别当前 PM 工作类型，而不是默认进入单一路径
- 模糊输入时使用 `AskUserQuestion` 做工作类型分流
- 需求型工作会创建或恢复 `meta/workbench-state.md`
- 澄清阶段后，用户已选择本次分析维度
- 后续只执行被选维度对应的 SOP
- 每步都可接续、回退、停顿

### ❌ 失败
- 一上来就默认执行完整需求流程
- 不经用户确认就替用户选择工作类型或分析维度
- 没有状态文件就继续推进需求型工作
- 用户没选 Story / 指标 / NFR / 治理 / 路线图，却自动生成产物
- 工作台仍然主要在做跨职能 handoff

<IMPORTANT>
工作台的职责是“分流 + 接续 + 渐进加载”，不是把所有能力都塞进一条固定流水线。
</IMPORTANT>