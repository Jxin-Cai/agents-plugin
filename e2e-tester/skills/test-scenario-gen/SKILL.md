---
name: test-scenario-gen
description: 基于 BDD + 风险 + Oracle 模型生成 E2E 测试剧本。当用户提到"生成测试剧本"、"创建测试场景"、"写测试用例"，或在 /e2e 流程的剧本阶段时触发。
allowed-tools: Read, Glob, Write, AskUserQuestion
---

# 专业测试剧本生成器

基于测试任务文件和项目上下文，生成 BDD（Given-When-Then）格式的专业 E2E 测试剧本。剧本不只是步骤清单，而是业务场景、多个 case、风险、准备、验证方法和证据要求的组合。

---

## 触发条件

- `/e2e` 流程的 Step 3 调用
- 用户主动要求“生成测试剧本”“创建测试场景”

---

## 前置条件

1. 需要有来自 `clarify-scope` 的测试任务文件：`.e2e-tests/{domain}/task/task.md`
2. 需要有来自 `scan-context` 的上下文摘要（除非用户明确跳过）
3. 需要先读取 `.e2e-tests/{domain}/task/index.md`，识别已挂载的共享数据集、mock、helper、历史脚本
4. 检索 `.e2e-tests/registry/index.yaml`（查看已有脚本避免编号冲突）和 `.e2e-tests/asset-catalog.md`（跨 domain 可复用资产）

---

## 提问规则

1. 所有阶段选择使用 `AskUserQuestion`
2. 默认允许用户用 Other 提供自定义场景、case 或调整意见
3. 当用户可能同时想“加 case + 调整优先级 + 删除某个 case”时，使用 `multiSelect: true`
4. 如果已有剧本文件存在，应优先引导用户确认“沿用 / 修改 / 追加”，而不是无条件重写

---

## 执行流程

### Step 1: 规划剧本列表，而不是堆在一个文件里

基于测试任务文件，先规划“业务场景 → 剧本文件”的映射，再写具体内容。

规划原则：
- **一个业务场景一个剧本**
- 同一剧本下可以有多个 case，但 case 必须服务于同一业务场景
- 不同角色、异常路径、边界状态如果仍围绕同一业务场景，可作为该剧本内不同 case
- 不相关功能不得塞进同一剧本

每个业务场景至少考虑以下 case 类型：
- **Happy Path** — 必须
- **Key Exception** — 必须
- **Boundary / State Transition** — 建议
- **Permission / Persona** — 存在则必须
- **Async / Eventual Consistency** — 涉及异步则必须
- **Idempotency** — 涉及写操作则建议

如果已存在 `.e2e-tests/{domain}/scenarios/TS-*.md`，先读取并判断：
- 直接沿用
- 在现有剧本里追加 case
- 重排剧本边界
- 新增一个业务场景剧本

使用 **AskUserQuestion** 向用户展示规划的剧本列表和各剧本内的 case 设计，确认优先级；当可能同时调整多个剧本或多个 case 时，使用 `multiSelect: true`。

### Step 2: 设计每个剧本内的 case oracle

对每个 case，明确回答以下问题：

1. **为什么测这个 case** — 它覆盖什么风险或业务承诺？
2. **通过要看什么信号** — UI / API / Data / Side Effect 哪些是必须验证的？
3. **失败时最担心什么** — 脏数据、重复操作、越权、通知缺失、状态不一致、异步链路断裂、补偿未执行？
4. **需要什么准备** — 账号、数据、权限、Mock、特性开关、环境状态？
5. **是否可复用现有资产** — 哪些数据集、mock、helper、历史脚本可以直接用？
6. **是否适合自动化** — 可机械验证 / 需先探索 / 暂不适合自动化

如果 case 只有 UI 信号，没有业务结果信号，要重新设计，不能直接写剧本。

### Step 3: 生成或更新剧本

**条件加载参考文档**：
- 读取 `references/scenario-template.md` 获取剧本模板结构（仅读取 Frontmatter 和正文结构部分，不在对话中复述全文）
- 当剧本涉及 mock 依赖时，**才读取** `references/mock-strategy.md`
- 当涉及契约校验、故障注入或有状态依赖时，**才读取** `references/mock-strategy-advanced.md`

按模板逐个生成或更新剧本文件。

关键要求：
- Frontmatter 必须包含：goal、risk_level、persona、business_scenario、case_count、out_of_scope、prep_ref、oracle_types、dependencies
- 需要记录当前剧本复用了哪些数据集 / mock / helper / 历史脚本
- 有 `strategy: mock` 的依赖 → 同步生成或引用 mock 配置文件
- 有 `strategy: fixture` 的依赖 → 同步生成或引用 fixture / dataset 文件
- 每个剧本内必须有多个 case，并提供 case matrix
- 若剧本已存在，默认在保留已有有效内容的基础上更新，不擅自删除已确认 case

### Step 4: 输出文件

将生成的剧本写入：`.e2e-tests/{domain}/scenarios/TS-{NNN}-{slug}.md`

如果 `scenarios/` 不存在，先创建。

### Step 5: 更新任务索引并用户审阅

生成后：
1. 在 `.e2e-tests/{domain}/task/index.md` 中登记：剧本路径、业务场景、case 数、复用资产、是否自动化优先
2. 向用户展示剧本列表和每个剧本的关键 oracle
3. 使用 **AskUserQuestion** 询问：
   - 确认剧本，进入准备阶段
   - 需要补充 oracle
   - 需要调整剧本优先级
   - 需要增加/删除剧本或 case
   - 其他自定义调整
4. 当可能同时修改多项时，使用 `multiSelect: true`
5. 根据反馈修改后保存最终版本

**⏸️ 等待用户确认后结束。**

---

## 约束

1. **剧本不是操作清单** — 必须体现业务场景、case、风险、目标、oracle、准备和证据要求
2. **严禁只写 UI** — 关键业务结果不得只用 UI 文案证明
3. **一剧本一业务场景** — 不相关功能不塞进同一剧本
4. **一剧本多 case，逐个验证** — case 必须可单独判断通过/失败
5. **操作可映射** — 操作描述要精确到可被 Playwright 执行或被 API 脚本映射
6. **编号全局唯一** — 检查 `registry/index.yaml` 及各域注册表确保编号不冲突
7. **准备引用必须明确** — 每个剧本都要指向 `prep_ref`
8. **优先复用资产** — 能从任务文件或共享目录复用的内容，不要重新发明
9. **支持中断接续** — 已有剧本时优先在原文件体系上续写、补 case 或重审

<IMPORTANT>
如果一个剧本无法回答“这个业务场景是什么”“有哪些 case”“怎么证明真的通过”“需要什么准备”，不能进入执行阶段。
</IMPORTANT>
