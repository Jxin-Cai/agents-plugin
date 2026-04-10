---
name: test-runner
description: 基于专业 E2E 剧本执行测试并生成质量报告。当用户提到"执行测试"、"跑测试"、"运行剧本"，或在 /e2e 流程的执行阶段时触发。
allowed-tools: Read, Glob, Write, AskUserQuestion, Bash(playwright-cli:*), Bash(npx playwright*), Bash(npx tsx*), Bash(mkdir*)
---

# E2E 测试执行器

读取任务文件、剧本和准备方案，通过准备度门禁、三路径执行策略和多层 oracle 验证执行测试。目标不是“跑完步骤”，而是给出可信的测试结论，并把复用/新增资产回写到索引里。

---

## 提问规则

1. 所有选择必须使用 `AskUserQuestion`
2. 默认允许用户通过 Other 输入不在预设选项中的后续动作
3. 当用户可能同时想“查看失败分析 + 补充准备 + 修改剧本”时，使用 `multiSelect: true`
4. 如果已有报告存在，应优先问“基于已有报告继续什么动作”，而不是默认重跑

---

## 触发条件

- `/e2e` 流程的 Step 5 调用
- 用户引用 `.e2e-tests/{domain}/scenarios/TS-*.md` 剧本文件
- 用户提到“执行测试”“跑测试”“运行剧本”

---

## 前置条件

> **回归模式豁免**：通过 `run-suite` 触发时，不要求剧本和准备方案文件。脚本 JSDoc 元数据提供充足上下文。以下前置条件仅适用于设计模式执行。

必须有对应的准备方案：`.e2e-tests/{domain}/prep/TP-{NNN}-*.md`

---

## 执行流程

### 阶段 0: 读取输入并做 readiness gate

1. **读取任务主文件**：`.e2e-tests/{domain}/task/task.md` 与 `.e2e-tests/{domain}/task/index.md`
2. **读取剧本**：解析 `.e2e-tests/{domain}/scenarios/TS-{NNN}-*.md`
   - 提取 frontmatter 全部字段
   - 解析 business scenario、case matrix、所有 case 和 step
3. **读取准备方案**：解析 `.e2e-tests/{domain}/prep/TP-{NNN}-*.md`
4. **读取已有报告（如存在）**：优先检查是否已有同一剧本的历史报告，判断是重跑、补证据、补 case，还是进入沉淀
5. **读取 quality-ledger**（如存在）：`.e2e-tests/quality-ledger.md`
   - 提取与当前剧本涉及服务相关的**时序基线**（用于设置轮询超时）
   - 提取与当前服务相关的**失败模式**（辅助归因）
   - 提取**环境陷阱**（提前规避已知问题）
6. **准备度门禁**：读取准备方案中的 readiness 结论。若为 BLOCKED，停止执行并产出 BLOCKED 报告。
7. **依赖健康探测**：对准备方案中策略为 `real` 的依赖服务，执行健康检查。任一关键依赖不可用时：
   - 如有降级方案（切 mock）→ 记录降级并继续
   - 无降级方案 → 标记 BLOCKED，停止执行

### 阶段 1: 先检索可复用资产，再做路径决策

查询以下来源：
- `.e2e-tests/registry/index.yaml` → 按需读取 `registry/{domain}.yaml`（优先当前 domain，跨 domain 检索走 asset-catalog.md）
- `.e2e-tests/asset-catalog.md`（跨 domain 资产发现的主入口）
- `.e2e-tests/{domain}/task/task.md`
- `.e2e-tests/{domain}/task/index.md`

匹配逻辑：
1. 精确匹配：剧本编号 + business_scenario + persona + match_keys
2. 模糊匹配：同 domain 下 tags/covers/risk_level/oracle_types/依赖画像
3. 辅助匹配：共享数据集、mock、helper 是否已齐备

**决策规则**：
- **路径 A：已有脚本** → 直接执行
- **路径 B：生成脚本后执行** → 仅在满足以下条件时允许：
  - 剧本内各 case 的 oracle 可以机械验证
  - 准备方案完整
  - 页面结构和交互稳定
  - 没有复杂异步链路需要先探索
- **路径 C：Playwright 探索** → 其他情况全部走此路径

如果条件不明确，优先路径 C，而不是冒险直接自动生成脚本。

---

### 路径 A: 自动化执行

查看注册表中 `type` 字段判断脚本类型：

**纯 API 脚本**（`type: api-script`）：
```bash
npx tsx .e2e-tests/{domain}/automation/ts-{nnn}-*.test.ts
```

**E2E 脚本**（`type: e2e-script`）：
```bash
npx playwright test .e2e-tests/{domain}/automation/ts-{nnn}-*.spec.ts --reporter=json
```

执行后：
- 解析执行结果（exit code + stdout/stderr）
- 映射到剧本的 case / step / oracle 结构
- 如脚本本身报错，归类为 **automation defect**，而不是产品失败

---

### 路径 B: 生成脚本后执行

1. 调用 `test-automation-builder` 生成脚本
2. 生成后执行脚本
3. 若失败：
   - 若为脚本稳定性问题 → automation defect
   - 若为场景理解不足 / oracle 不清 → requirement/oracle unclear
   - 若为无法稳定复现的交互 → 降级到路径 C

---

### 路径 C: Playwright 探索执行

> **条件加载**：仅当路径决策为 C 时，读取 `references/playwright-explore-guide.md`。路径 A/B 不读取此文件。

按 playwright-explore-guide.md 中的步骤（打开浏览器 → 逐 case 执行 Given/When/Then → **拦截并记录 API 调用链** → 失败分类 → 关闭浏览器）完成探索式测试。

**路径 C 的双重目标**：
1. 验证业务场景下每个 case 是否通过
2. **提炼 API 调用链**——记录每个 case 的关键操作触发了哪些接口请求、参数和返回值，为后续沉淀纯 API 脚本提供知识输入

---

### 阶段 3: 生成质量报告

> **条件加载**：此时才读取 `references/report-template.md` 获取报告结构。不要在阶段 0/1/2 提前读取。

生成 `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md`

报告必须包含：
1. 准备度结论
2. 执行方式与整体结果
3. 风险覆盖情况
4. oracle 完整度
5. **case 执行汇总**
6. 场景与步骤细节
7. 失败分类与置信度
8. flaky 观察与治理建议
9. **复用/新增资产汇总**
10. 未覆盖项与后续建议

> **条件加载**：当剧本包含 `async` 或 `idempotency` oracle，或执行中出现 flaky 现象时，读取 `references/async-and-flaky-guide.md` 获取详细的异步验证策略和 flaky 治理规范。

### 阶段 4: 沉淀判断与索引回写

仅当满足以下条件时建议沉淀为自动化脚本（API 脚本或 E2E 脚本）：
- 测试路径成立且证据完整
- **核心操作有对应的 API 端点**（从探索过程中已确认）→ 建议 `api-script`
- **核心操作必须通过 UI 完成，但验证点明确且页面结构稳定** → 建议 `e2e-script`
- **状态验证可通过查询接口完成**
- 准备方案可重复
- 当前结论不是偶发或环境噪音

否则应明确说明：暂不适合自动化沉淀，原因是什么。

完成后在 `.e2e-tests/{domain}/task/index.md` 中回写（格式参照 `references/index-template.md` 的 Stage 5 区块）：
- 报告路径
- 路径决策（A/B/C）
- 每个 case 的执行结果
- 复用的资产
- 本次新增的证据或候选沉淀资产
- 如执行中发现前置阶段认知有误（如调用链遗漏、依赖策略需调整），在 index.md 的"后续修正记录"中追加条目

### 阶段 4.5: 回写跨任务知识

**回写 quality-ledger**（`.e2e-tests/quality-ledger.md`，如不存在则按 `references/quality-ledger-template.md` 初始化）：
- **失败模式**：每个 FAIL case 的归因，如果与已有模式匹配则更新复现次数，否则新增条目
- **时序基线**：异步操作的实际等待时间（轮询了多久、一致性窗口多长）
- **环境陷阱**：执行中遇到的环境问题（依赖不稳定、配置差异、数据污染）
- **依赖稳定性**：本次执行中各依赖的可用性记录
- **Flaky 治理**：本次出现的 flaky 现象和根因分类

**回写 system-map**（`.e2e-tests/system-map.md`）：
- **实测验证**：路径 C 探索中发现的 API 端点、调用链、认证方式，作为对 system-map 的实测验证
- 更新已有条目的 `最后验证` 日期
- 新发现的端点/调用链追加到对应区块

### 阶段 5: 用户决定后续动作

使用 `AskUserQuestion` 展示后续动作：
- 继续补证据
- 补充准备后重测
- 修改剧本后重测
- 进入自动化沉淀
- 结束当前轮次
- 其他自定义动作

当多个动作可并行规划时，使用 `multiSelect: true`。

---

## 约束

1. **无准备不执行** — 没有 prep 方案或 prep 不充分，不执行
2. **无关键证据不判 PASS** — 关键业务结果需要数据/副作用证据时，只有 UI 成功不算通过
3. **失败必须归类** — 不要只写 FAIL，要说明更像哪类问题
4. **Playwright 不是默认选项** — 但在不确定时，要优先探索而不是冒险生成低质量脚本
5. **报告必须体现可信度** — 不是只汇总执行过程，而是交付测试判断
6. **优先复用已有资产** — 路径决策前先查共享资产和历史脚本，不要默认从零执行
7. **按 case 判定** — 剧本内多个 case 必须逐个给出 PASS / FAIL / BLOCKED / SKIP
8. **支持中断接续** — 有历史报告时，优先基于已有结论决定下一步，而不是默认整轮重跑

<IMPORTANT>
关键 oracle 缺失时，即使页面表现正常，也不能判 PASS。
</IMPORTANT>
