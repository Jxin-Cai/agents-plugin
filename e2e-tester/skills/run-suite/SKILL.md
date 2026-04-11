---
name: run-suite
description: 批量回归执行器——按套件/域/标签/脚本列表批量执行已有自动化脚本，生成轻量回归报告。当用户说"跑回归"、"回归测试"、"跑套件"、"run suite"、"regression"时触发。
argument-hint: "<suite名 | domain名 | tag过滤 | 脚本列表>"
allowed-tools: Read, Glob, Write, Skill, Bash(npx tsx*), Bash(npx playwright*), Bash(mkdir*), AskUserQuestion
---

# 批量回归执行器

跳过所有设计仪式（无澄清、无扫描、无剧本、无准备方案）。脚本是成熟的，自描述的——直接执行，快速反馈。

---

## 核心理念

回归模式 ≠ 设计模式的快进。回归模式有自己的价值观：

- **速度优先**：脚本间无交互门禁，失败不中断批次
- **脚本即规格**：不需要 task.md、scenario、prep 文件。脚本 JSDoc 元数据就是全部上下文
- **轻量报告**：一行一脚本摘要，仅失败展开。不生成 11 节完整报告
- **知识缓存可选**：quality-ledger 存在时读取时序基线和环境陷阱，不存在就跳过

---

## 执行流程

### Step 0: 解析输入并确认脚本列表

从 `$ARGUMENTS` 解析执行目标，支持以下输入格式：

| 输入格式 | 示例 | 解析方式 |
|---------|------|---------|
| 套件名 | `smoke` | 读取 `registry/suites.yaml`，按套件配置解析 |
| 域名 | `user-auth` | 读取 `registry/user-auth.yaml`，取全部脚本 |
| 标签过滤 | `tags:payment` | 遍历所有域注册表，按 tags 匹配 |
| 风险过滤 | `risk:High` | 遍历所有域注册表，按 risk_level 匹配 |
| 显式列表 | `ts-001,ts-003,ts-007` | 从注册表中查找对应脚本路径 |

解析步骤：

1. 读取 `.e2e-tests/registry/index.yaml`
2. 如果是套件名 → 读取 `registry/suites.yaml` → 按套件解析规则解析（显式列表优先，否则动态过滤）
3. 如果是域名 → 读取 `registry/{domain}.yaml` → 取全部非 stale 脚本
4. 如果是标签/风险过滤 → 遍历所有域注册表匹配
5. 如果是显式列表 → 逐个从注册表查找

知识缓存加速（可选）：
- 如果 `.e2e-tests/quality-ledger.md` 存在，读取时序基线（用于判断超时）和环境陷阱（提前警告）
- 如果不存在，跳过，不报错

用 `AskUserQuestion` 向用户展示解析结果（**单次确认，非多阶段门禁**）：
- 脚本列表（路径、类型、域、风险等级）
- 预估执行时间
- 如 quality-ledger 中有相关环境陷阱，一并展示

用户可移除脚本或确认执行。

### Step 1: 顺序执行

逐个执行脚本，按 `type` 选择执行器：

```bash
# type: api-script
npx tsx .e2e-tests/{domain}/automation/{script}.test.ts

# type: e2e-script
npx playwright test .e2e-tests/{domain}/automation/{script}.spec.ts --reporter=json
```

每个脚本记录：
- exit code
- stdout / stderr（截断至 50 行）
- 执行耗时
- PASS / FAIL / ERROR 判定

**关键规则**：
- 脚本间**无 `AskUserQuestion`**，不停顿
- 某个脚本失败 → **记录失败，继续执行下一个**，不中断批次
- 脚本执行超时（单脚本 > 60s API / > 120s E2E）→ 标记 TIMEOUT，继续

### Step 2: 生成轻量回归报告

按 `references/regression-report-template.md` 生成报告。

写入路径：`.e2e-tests/reports/regression-{YYYY-MM-DD}-{HHmm}.md`

报告内容：
- 执行摘要（一行一脚本表）
- 仅失败脚本展开详情（错误类型、退出码、错误输出、可能原因、建议动作）
- 注册表更新记录

### Step 3: 更新注册表

逐个更新 `registry/{domain}.yaml`：

| 结果 | 更新字段 |
|------|---------|
| PASS | `last_passed` → today, `fail_count` → 0, `stale` → false |
| FAIL | `last_failed` → today, `fail_count` += 1 |
| TIMEOUT | 同 FAIL |

同步更新 `registry/index.yaml` 的 `last_updated`。

### Step 4: 展示结果并建议后续

用 `AskUserQuestion`（`multiSelect: true`）展示：

- 通过/失败/超时统计
- 失败脚本摘要
- 后续动作选项：
  - 全部通过，完成
  - 修复失败脚本（→ 调用 `fix-script`）
  - 重跑失败脚本
  - 查看完整报告
  - 其他自定义动作

---

## 约束

1. **无设计产物要求** — 不需要 task.md、scenario、prep。脚本在注册表中即可执行
2. **脚本必须在注册表中** — 未注册的脚本路径被拒绝，建议先通过设计模式沉淀
3. **不做 readiness gate** — 脚本自身负责 setup/teardown，回归模式不检查外部准备度
4. **不生成完整报告** — 只用轻量格式。需要深度分析的失败应转入 fix-script 或设计模式
5. **quality-ledger 缺失不阻塞** — 存在时加速，缺失时跳过

<IMPORTANT>
回归模式的目标是"快速知道哪些坏了"，不是"深度分析每个测试"。
保持轻量。不要在回归执行中引入设计模式的仪式。
</IMPORTANT>
