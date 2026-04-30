---
name: aa
description: 无障碍审计工作台——先装配任务，再按意图路由到 WCAG 审计、辅助技术测试、合规报告或完整流程
argument-hint: "<审计目标描述（页面URL、组件名称或功能模块）>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 无障碍审计工作台

用户传入的参数：`$ARGUMENTS`

先装配无障碍审计任务，再带他进入对应 workflow。不是所有需求都需要走完整 WCAG → AT → 合规报告管道。

**入口纪律**：除非用户明确点名 `/wcag-audit`、`/assistive-tech-test`、`/compliance-report`，或明确要求“只做 WCAG / 只做辅助技术测试 / 只做合规报告 / 只做快速扫描”，否则都先走 `/accessibility-auditor:aa` 入口。像“帮我看下这个页面无障碍问题”“发版前做个可访问性体检”这类泛化请求，一律先完成任务装配，再决定 workflow。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整三阶段管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "WCAG / POUR / 可感知 / 可操作" | wcag-only | 调用 `/wcag-audit $ARGUMENTS` |
| "辅助技术 / 屏幕阅读器 / 键盘导航" | at-test-only | 调用 `/assistive-tech-test $ARGUMENTS` |
| "合规 / VPAT / ACR / 报告" | report-only | 调用 `/compliance-report $ARGUMENTS` |
| "快速扫描 / 快查 / 概览" | quick-scan | → Step 3 |
| "继续上次无障碍任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整审计 / 全面检查" 或复杂需求 | full-audit | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `target_scope`：页面 / 组件 / 流程
- `target_standard`：WCAG2.1AA / WCAG2.2AA / 508 / EN301549
- `evidence_level`：light / standard / strict
- `acceptance_source`：user-text / markdown / url / doc
- `entry_intent`：用户原话
- `current_stage`：wcag / assistive-tech / report
- `completed_stages`：已完成阶段
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

> 仅 `full-audit` workflow 需要此步。

1. 从 `$ARGUMENTS` 提取审计目标，生成英文缩写（2-4 词）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_accessibility/{当前日期}-{缩写}/` 及子目录 `context/` `wcag/` `assistive-tech/` `reports/` `meta/`
4. 初始化 `meta/audit-state.md`：

```markdown
workflow_mode: full-audit
task_type: full-audit
entry_intent: {用户原话}
target_scope: {页面/组件/流程}
target_standard: WCAG2.1AA
evidence_level: standard
acceptance_source: user-text
current_stage: wcag
completed_stages: []
next_step: wcag-audit
last_updated: {YYYY-MM-DD}
last_report: 
```

5. 扫描 `wcag/`、`assistive-tech/`、`reports/` 中已有产物，检查接续点（产物优先于状态文件）
6. 使用 `AskUserQuestion` 确认从哪里开始

**⏸️ 等待用户确认。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/audit-state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| WCAG 审计 | `/wcag-audit $ARGUMENTS` | `wcag/wcag-audit-*.md` | 继续 / 补充 / 结束 |
| 辅助技术测试 | `/assistive-tech-test $ARGUMENTS` | `assistive-tech/at-test-*.md` | 继续 / 回退 / 结束 |
| 合规报告 | `/compliance-report $ARGUMENTS` | `reports/compliance-report-*.md` | 完成 |

每阶段完成后写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速无障碍扫描

编排器内轻量执行（不调用子技能）：

1. **感知性速查**：图片 alt 文本、颜色对比度、表单标签
2. **可操作性速查**：键盘可达性、焦点顺序、触控目标尺寸
3. **可理解性速查**：语言标注、错误提示、一致性导航
4. **健壮性速查**：语义 HTML、ARIA 属性、兼容性

生成精简报告到 `_accessibility/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整审计 / 结束。

---

## 断点恢复

1. 扫描 `_accessibility/` 下未完成目录
2. 先 Read `meta/audit-state.md`，再验 `wcag/`、`assistive-tech/`、`reports/` 产物目录
3. 产物优先于状态文件；恢复时只问一次 `AskUserQuestion`：从断点继续 / 重新开始 / 从某阶段重开
4. 每阶段结束写 `meta/{stage}-summary.md`（≤20 行）作为恢复锚点

<IMPORTANT>
工作台的职责是"先装配无障碍审计任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
每个阶段完成后必须等待用户确认再进入下一阶段。
产出文件与状态文件冲突时，以产出文件为准。
恢复时必须先读状态、再校验产物，不可只凭对话记忆推进。
WCAG Level A 违规必须标记为 Blocker，不可降级。
正式合规交付必须注明适用标准与证据级别，不可只给口头结论。
</IMPORTANT>
