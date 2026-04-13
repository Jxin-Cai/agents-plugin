---
name: acs
description: AI 引用优化工作台——按意图路由到引用审计、丢失分析、修复方案或完整流程
argument-hint: "<品牌/产品描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# AI 引用优化工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻的目标，再进入对应 workflow。不是所有需求都需要走完整审计 → 分析 → 修复管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整三阶段管道
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "审计 / 引用检测 / 品牌曝光度" | audit-only | 调用 `/citation-audit $ARGUMENTS` |
| "丢失 / 缺失 / 竞品赢了" | analysis-only | 调用 `/lost-prompt-analysis $ARGUMENTS` |
| "修复 / 优化方案 / fix" | fix-only | 调用 `/fix-pack-generation $ARGUMENTS` |
| "快速检查 / 快扫" | quick-check | → Step 3 |
| "完整流程 / 全套优化" 或复杂需求 | full-workflow | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 完整 AEO/GEO 优化流程（推荐）
- 仅引用审计
- 仅丢失查询分析
- 仅修复方案生成
- 快速引用检查

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

> 仅 `full-workflow` 需要此步。

1. 从 `$ARGUMENTS` 提取品牌/产品，生成英文缩写
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_ai-citation/{当前日期}-{缩写}/` 及子目录 `context/` `audit/` `analysis/` `fix-packs/` `meta/`
4. 采集品牌基础信息（品牌名、主域名、品类、受众、竞品），保存到 `context/brand-profile.md`
5. 初始化 `meta/citation-state.md`（workflow_mode、completed_steps、next_step）
6. 扫描已有目录，检查接续点（产物优先）

**⏸️ 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/citation-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 引用审计 | `/citation-audit $ARGUMENTS` | `audit/citation-audit-*.md` | 继续 / 补充 / 结束 |
| 丢失分析 | `/lost-prompt-analysis $ARGUMENTS` | `analysis/lost-prompt-analysis-*.md` | 继续 / 回退 / 结束 |
| 修复方案 | `/fix-pack-generation $ARGUMENTS` | `fix-packs/fix-pack-*.md` | 完成 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速引用检查

编排器内轻量执行：
1. 用户提供品牌名和 3 个核心查询词
2. 模拟 AI 搜索场景评估品牌是否被引用
3. 生成精简评分卡到 `_ai-citation/quick-check-{日期}.md`

使用 `AskUserQuestion`：深入分析 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_ai-citation/` 下未完成目录
2. Read `meta/citation-state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
引用审计的结论必须基于实际检测数据，不可凭假设判定。
SOV 和引用率计算必须标注查询日期和平台版本，不可跨日期/跨平台混合计算。
修复方案的预期效果必须标注为"预期"而非"保证"——AI 引用受模型版本和上下文影响，不可承诺确定性结果。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
