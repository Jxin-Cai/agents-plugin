---
name: test-scenario-gen
description: 基于 BDD + 风险 + Oracle 模型生成 E2E 测试剧本。当用户提到"生成测试剧本"、"创建测试场景"、"写测试用例"，或在 /e2e 流程的剧本阶段时触发。
allowed-tools: Read, Glob, Write, AskUserQuestion
---

# 专业测试剧本生成器

基于测试任务定义和项目上下文，生成 BDD（Given-When-Then）格式的专业 E2E 测试剧本。剧本不只是步骤清单，而是风险、准备、验证方法和证据要求的组合。

---

## 触发条件

- `/e2e` 流程的 Step 3 调用
- 用户主动要求“生成测试剧本”“创建测试场景”

---

## 前置条件

1. 需要有来自 `clarify-scope` 的测试任务定义
2. 需要有来自 `scan-context` 的上下文摘要（除非用户明确跳过）

---

## 执行流程

### Step 1: 规划场景矩阵

基于测试任务定义，先规划场景矩阵，再写具体剧本。

每个核心流程至少考虑以下维度：
- **Happy Path** — 正向主路径，必须
- **Key Exception** — 关键异常路径，必须
- **Boundary** — 关键边界或状态切换，建议
- **Permission / Persona** — 角色差异场景，存在则必须
- **Async / Eventual Consistency** — 异步链路场景（涉及 MQ、回调、Saga），存在则必须
- **Idempotency** — 幂等性场景（重复提交是否安全），涉及写操作则建议
- **Fault Tolerance** — 下游超时/降级/部分失败时的行为，微服务链路建议

使用 **AskUserQuestion** 向用户展示规划的场景矩阵，确认优先级。

### Step 2: 设计每个场景的 oracle

对每个场景，明确回答以下问题：

1. **为什么测这个场景** — 它覆盖什么风险或业务承诺？
2. **通过要看什么信号** — UI / API / Data / Side Effect 哪些是必须验证的？
3. **失败时最担心什么** — 脏数据、重复操作、越权、通知缺失、状态不一致、异步链路断裂、补偿未执行？
4. **需要什么准备** — 账号、数据、权限、Mock、特性开关、环境状态？
5. **是否涉及异步** — 操作结果是否需要等待异步处理完成？一致性窗口多长？用什么方式轮询确认？
6. **是否需要验证幂等性** — 同一请求重复提交是否安全？是否产生重复数据或重复副作用？

如果场景只有 UI 信号，没有业务结果信号，要重新设计，不能直接写剧本。

### Step 3: 生成剧本

**条件加载参考文档**：
- 读取 `references/scenario-template.md` 获取剧本模板结构（仅读取 Frontmatter 和正文结构部分，不在对话中复述全文）
- 当剧本涉及 mock 依赖时，**才读取** `references/mock-strategy.md`
- 当涉及契约校验、故障注入或有状态依赖时，**才读取** `references/mock-strategy-advanced.md`

按模板逐个生成剧本文件。

关键要求：
- Frontmatter 必须包含：goal、risk_level、persona、out_of_scope、prep_ref、oracle_types、dependencies
- 有 `strategy: mock` 的依赖 → 同步生成或引用 mock 配置文件
- 有 `strategy: fixture` 的依赖 → 同步生成或引用 fixture 文件

### Step 4: 输出文件

将生成的剧本写入：`{domain}/scenarios/TS-{NNN}-{slug}.md`

如果 `{domain}/scenarios/` 不存在，先创建。

### Step 5: 用户审阅

生成后：
1. 向用户展示场景矩阵和关键 oracle
2. 使用 **AskUserQuestion** 询问：
   - 确认剧本，进入准备阶段
   - 需要补充 oracle
   - 需要调整场景优先级
   - 需要增加/删除场景
3. 根据反馈修改后保存最终版本

**⏸️ 等待用户确认后结束。**

---

## 约束

1. **剧本不是操作清单** — 必须体现风险、目标、oracle、准备和证据要求
2. **严禁只写 UI** — 关键业务结果不得只用 UI 文案证明
3. **场景必须有价值说明** — 不能机械地把每个按钮都写成场景
4. **一剧本一流程** — 不相关功能不塞进同一剧本
5. **操作可映射** — 操作描述要精确到可被 Playwright 执行
6. **编号全局唯一** — 检查 registry.yaml 确保编号不冲突
7. **准备引用必须明确** — 每个剧本都要指向 `prep_ref`

<IMPORTANT>
如果一个剧本无法回答”为什么测””怎么证明真的通过””需要什么准备”，不能进入执行阶段。
</IMPORTANT>
