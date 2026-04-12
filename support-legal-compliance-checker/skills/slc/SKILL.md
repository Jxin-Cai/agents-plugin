---
name: slc
description: 法律合规检查工作台——按意图路由到合规审计、隐私政策、合同审查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 法律合规检查工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "合规 / 审计 / 法规" | audit-only | 调用 `/compliance-audit $ARGUMENTS` |
| "隐私 / GDPR / 个人信息" | privacy-only | 调用 `/privacy-policy $ARGUMENTS` |
| "合同 / 条款 / 协议" | contract-only | 调用 `/contract-review $ARGUMENTS` |
| "快速检查 / 概览" | quick-check | → Step 3 |
| "完整合规 / 全套 或复杂需求" | full-compliance | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅合规 
- 仅隐私 
- 仅合同 
- 快速合规管理检查
- 完整合规管理流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_legal-compliance/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 合规审计 | `/compliance-audit $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 隐私政策 | `/privacy-policy $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 合同审查 | `/contract-review $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

按以下维度逐项速览，每项给出风险等级（高/中/低/不适用）+ 1-2 句结论：

| 维度 | 检查要点 |
|------|---------|
| 合规风险 | 适用法规识别、关键合规差距、近期处罚风险 |
| 隐私风险 | 数据处理合法性、用户权利保障、跨境传输合规 |
| 合同风险 | 高风险条款识别、数据保护条款完备性、责任条款合理性 |

生成精简报告（不超过 30 行）保存到 `_legal-compliance/quick-scan-{日期}.md`，包含各维度风险等级、关键发现和建议下一步。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_legal-compliance/` 下未完成目录（排除 `quick-scan-*` 文件）
2. Read `meta/state.md` 获取 `completed_steps` 和 `next_step`
3. 逐目录检查产出文件判定实际进度：
   - `audits/compliance-assessment-report.md` 存在 → 合规审计已完成
   - `policies/privacy-policy.md` 存在 → 隐私政策已完成
   - `contracts/contract-review-report.md` 存在 → 合同审查已完成
4. 若产出文件与 `state.md` 记录冲突，以产出文件为准
5. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
合规建议必须引用具体法规条款。
明确标注「不构成法律意见」。
不可猜测法规要求，不确定时必须声明。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
