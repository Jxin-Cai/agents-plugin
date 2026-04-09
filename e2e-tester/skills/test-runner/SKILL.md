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

```bash
npx playwright test .e2e-tests/{domain}/automation/ts-{nnn}-*.spec.ts --reporter=json
```

执行后：
- 解析 JSON 结果
- 收集截图 / trace / 输出文件
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

读取 `references/playwright-explore-guide.md`，按其中的步骤（打开浏览器 → 逐场景执行 Given/When/Then → 失败分类 → 关闭浏览器）完成探索式测试。

---

### 阶段 3: 生成质量报告

读取 `references/report-template.md`，生成 `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md`

报告必须包含：
1. 准备度结论
2. 执行方式与整体结果
3. 风险覆盖情况
4. oracle 完整度
5. 证据完整度
6. 场景与步骤细节
7. 失败分类与置信度
8. flaky suspicion
9. 未覆盖项与后续建议

### 阶段 4: 沉淀判断

仅当满足以下条件时建议沉淀：
- 测试路径成立且证据完整
- 关键 oracle 可稳定自动化
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
测试通过的定义不是“步骤都跑完了”，而是“业务承诺被可信地验证了”。
关键 oracle 缺失时，即使页面表现正常，也不能判 PASS。
</IMPORTANT>
