---
name: test-runner
description: 基于专业 E2E 剧本执行测试并生成质量报告。当用户提到"执行测试"、"跑测试"、"运行剧本"，或在 /e2e 流程的执行阶段时触发。
allowed-tools: Read, Glob, Write, AskUserQuestion, Bash(playwright-cli:*), Bash(npx playwright*), Bash(mkdir*)
---

# E2E 测试执行器

读取剧本和准备方案，通过准备度门禁、三路径执行策略和多层 oracle 验证执行测试。目标不是“跑完步骤”，而是给出可信的测试结论。

---

## 触发条件

- `/e2e` 流程的 Step 5 调用
- 用户引用 `.e2e-tests/{domain}/scenarios/TS-*.md` 剧本文件
- 用户提到“执行测试”“跑测试”“运行剧本”

---

## 前置条件

必须有对应的准备方案：`.e2e-tests/{domain}/prep/TP-{NNN}-*.md`

---

## 执行流程

### 阶段 0: 读取输入并做 readiness gate

1. **读取剧本**：解析 `.e2e-tests/{domain}/scenarios/TS-{NNN}-*.md`
   - 提取 frontmatter 全部字段
   - 解析所有 Scenario 和 Step

2. **读取准备方案**：解析 `.e2e-tests/{domain}/prep/TP-{NNN}-*.md`

3. **准备度门禁**：读取准备方案中的 readiness 结论。若为 BLOCKED，停止执行并产出 BLOCKED 报告。

4. **依赖健康探测**：对准备方案中策略为 `real` 的依赖服务，执行健康检查（`GET /health`、DB ping 等）。任一关键依赖不可用时：
   - 如有降级方案（切 mock）→ 记录降级并继续
   - 无降级方案 → 标记 BLOCKED，停止执行

### 阶段 1: 路径决策

查询 `.e2e-tests/registry.yaml` 匹配自动化脚本：

1. 精确匹配：剧本编号 + match_keys
2. 模糊匹配：同 domain 下 tags/covers/risk_level/oracle_types

**决策规则**：
- **路径 A：已有脚本** → 直接执行
- **路径 B：生成脚本后执行** → 仅在满足以下条件时允许：
  - 剧本的 oracle 可以机械验证
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

**遗留 Playwright 脚本**（`type: playwright`，仅历史兼容）：
```bash
npx playwright test .e2e-tests/{domain}/automation/ts-{nnn}-*.spec.ts --reporter=json
```

执行后：
- 解析执行结果（exit code + stdout/stderr）
- 映射到剧本的 Scenario / Step / Oracle 结构
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

读取 `references/playwright-explore-guide.md`，按其中的步骤（打开浏览器 → 逐场景执行 Given/When/Then → **拦截并记录 API 调用链** → 失败分类 → 关闭浏览器）完成探索式测试。

**路径 C 的双重目标**：
1. 验证业务场景是否通过
2. **提炼 API 调用链**——记录每个操作触发了哪些接口请求、参数和返回值，为后续沉淀纯 API 脚本提供知识输入

---

### 阶段 3: 生成质量报告

此时读取 `references/report-template.md` 获取报告结构，生成 `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md`

报告必须包含：
1. 准备度结论
2. 执行方式与整体结果
3. 风险覆盖情况
4. oracle 完整度（含 async / idempotency oracle，如涉及）
5. 证据完整度
6. 场景与步骤细节
7. 失败分类与置信度
8. flaky 观察与治理建议
9. 未覆盖项与后续建议

> **条件加载**：当剧本包含 `async` 或 `idempotency` oracle，或执行中出现 flaky 现象时，读取 `references/async-and-flaky-guide.md` 获取详细的异步验证策略和 flaky 治理规范。

### 阶段 4: 沉淀判断

仅当满足以下条件时建议沉淀为纯 API 自动化脚本：
- 测试路径成立且证据完整
- **核心操作有对应的 API 端点**（从探索过程中已确认）
- **状态验证可通过查询接口完成**
- 准备方案可重复
- 当前结论不是偶发或环境噪音

否则应明确说明：暂不适合自动化沉淀，原因是什么。

---

## 约束

1. **无准备不执行** — 没有 prep 方案或 prep 不充分，不执行
2. **无关键证据不判 PASS** — 关键业务结果需要数据/副作用证据时，只有 UI 成功不算通过
3. **失败必须归类** — 不要只写 FAIL，要说明更像哪类问题
4. **Playwright 不是默认选项** — 但在不确定时，要优先探索而不是冒险生成低质量脚本
5. **报告必须体现可信度** — 不是只汇总执行过程，而是交付测试判断

<IMPORTANT>
关键 oracle 缺失时，即使页面表现正常，也不能判 PASS。
</IMPORTANT>
