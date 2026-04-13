---
name: test-runner
description: 基于剧本和准备方案执行测试并生成质量报告
allowed-tools: Read, Glob, Write, Skill, AskUserQuestion, Bash(npx playwright*), Bash(npx tsx*), Bash(mkdir*)
---

# 测试执行器

通过准备度门禁、三路径策略和多层 oracle 验证执行测试，给出可信测试结论。

## 流程

### 阶段 0: 读取输入与 readiness gate

读取 `.e2e-tests/{domain}/task/task.md`、`.e2e-tests/{domain}/task/index.md`、`.e2e-tests/{domain}/scenarios/` 下的剧本、`.e2e-tests/{domain}/prep/` 下的方案、已有报告、`.e2e-tests/quality-ledger.md`（只提取与当前 domain 相关的时序基线、失败模式、环境陷阱条目）。
- readiness = BLOCKED → 停止执行
- real 依赖不可用且无降级 → BLOCKED

**证据级别确认**：从 `.e2e-tests/{domain}/task/index.md` frontmatter 读取 `evidence_level`。若缺失，用 `AskUserQuestion` 引导选择：

| 选项 | 说明 | 默认推荐场景 |
|------|------|-------------|
| light | 关键截图 + 关键 API 出入参对 | design-lite、快速验证 |
| standard | 每步截图 + 完整 API 链 + 错误日志 | 一般场景（推荐） |
| strict | 密集截图序列 + 可访问性快照 + 全量日志 | release-gate、合规审计 |

选择后回写 `.e2e-tests/{domain}/task/index.md` frontmatter。

### 阶段 1: 资产检索与路径决策

查询 `.e2e-tests/registry/`、`.e2e-tests/asset-catalog.md`、task 文件。匹配已有脚本（精确 → 模糊 → 辅助）。

| 路径 | 条件 |
|------|------|
| A 自动化 | 已有脚本匹配 |
| B 生成后执行 | oracle 可机械验证 + prep 完整 + 页面稳定 |
| C Playwright 探索 | 其他情况（不确定时默认 C） |

### 阶段 2: 执行

#### 路径 A
```bash
# api-script: npx tsx .e2e-tests/{domain}/automation/ts-{nnn}-*.test.ts
# e2e-script: npx playwright test .e2e-tests/{domain}/automation/ts-{nnn}-*.spec.ts --reporter=json
```

#### 路径 B
调用 `test-automation-builder` 生成 → 执行 → 失败则降级到 C。

#### 路径 C
> **条件加载**：仅此时读取 `references/playwright-explore-guide.md`。

按 `evidence_level` 执行分级证据采集。逐 case 探索，拦截 API 调用链，收集证据，提炼接口知识。

### 阶段 3: 质量报告

> **条件加载**：此时读取 `references/report-template.md`。含 async/flaky 时才读 `references/async-and-flaky-guide.md`。

生成 `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md`。按 case 给出 PASS/FAIL/BLOCKED/SKIP。证据引用使用文件路径（如 `.e2e-tests/{domain}/evidence/{date}/TS-{NNN}-C{N}/screenshots/then-result.png`），不用自由文本。

### 阶段 4: 沉淀判断与索引回写

**产物沉淀**（已完成，确认落盘）：
- 剧本已在 `.e2e-tests/{domain}/scenarios/` ✓
- 准备方案已在 `.e2e-tests/{domain}/prep/` ✓
- 报告已在 `.e2e-tests/{domain}/reports/` ✓
- 证据已在 `.e2e-tests/{domain}/evidence/` ✓

**脚本沉淀判断**（需条件）：路径成立 + 证据完整 + 有 API 端点 + 准备可重复 → 建议沉淀为自动化脚本。条件不满足时在 index.md 记录原因，不强制。

回写 `.e2e-tests/{domain}/task/index.md`（报告路径、路径决策、case 结果、资产）。

### 阶段 4.5: 回写 quality-ledger

写入 `.e2e-tests/quality-ledger.md`（不存在时按 `skills/e2e/references/quality-ledger-template.md` 创建空结构后再写入）。

内容：失败模式、时序基线、环境陷阱、依赖稳定性、flaky 治理。

### 阶段 5: 后续动作

`AskUserQuestion`（multiSelect）：补证据 / 重测 / 修改剧本 / 沉淀为自动化脚本 / 结束。

**主动推荐**：如果脚本沉淀条件满足，将"沉淀为自动化脚本"标注为 (Recommended)。

### 落盘检查

确认以下文件已写入：
- `.e2e-tests/{domain}/reports/{date}/TS-{NNN}-run-{RRR}.md`（报告）
- `.e2e-tests/{domain}/task/index.md`（已更新）
- `.e2e-tests/quality-ledger.md`（已更新或新建）

缺失则补写。

## 约束

1. 无准备不执行
2. 无关键证据不判 PASS
3. 失败必须归类
4. 不确定时优先路径 C
5. 优先复用已有资产
6. 按 case 逐个判定

<IMPORTANT>
关键 oracle 缺失时，即使页面表现正常，也不能判 PASS。
</IMPORTANT>
