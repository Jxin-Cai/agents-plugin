---
name: uxr
description: UX 研究工作台——先装配任务，再按意图路由到访谈指南、可用性测试计划、用户画像、快速检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# UX 研究工作台

用户传入的参数：`$ARGUMENTS`

先装配 UX 研究任务，再带他进入对应 workflow。不是所有需求都需要走完整管道。

**入口纪律**：除非用户明确点名子 skill（`/interview-guide`、`/usability-test-plan`、`/persona-builder`），否则一律先走 `/ux-researcher:uxr` 做任务装配与路由；先装配后路由，不默认完整流程。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "访谈 / 用研 / 问题设计" | interview-only | 调用 `/interview-guide $ARGUMENTS` |
| "可用性 / 测试 / 用户测试" | usability-only | 调用 `/usability-test-plan $ARGUMENTS` |
| "画像 / persona / 用户特征" | persona-only | 调用 `/persona-builder $ARGUMENTS` |
| "快速检查 / 概览" | quick-scan | → Step 3 |
| "继续上次 UX 研究任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整研究 / 全套" 或复杂需求 | full-research | → Step 1 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：interview-only / usability-only / persona-only / quick-scan / full-research
- `workflow`：当前 workflow
- `entry_intent`：用户原话
- `trigger_source`：需求验证 / 问题复盘 / 新功能 / 长期研究
- `deliverable`：访谈脚本 / 测试计划 / 画像 / 组合交付物
- `target_users`：目标用户群
- `evidence_sources`：访谈 / 可用性 / 定量 / 现有资料
- `evidence_level`：light / standard / strict
- `acceptance_source`：user-text / markdown / doc
- `current_stage`：当前阶段
- `completed_stages`：已完成阶段
- `next_step`：下一步动作
- `status`：active / blocked / done

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 执行 `Bash(mkdir -p _ux-research/{当前日期}-{缩写}/{context,meta,interviews,tests,personas})`
4. Write `_ux-research/{当前日期}-{缩写}/meta/state.md`，初始内容：
   ```
   workflow_mode: full-research
   task_type: full-research
   entry_intent: {用户原话}
   trigger_source: research
   deliverable: study-pack
   target_users: []
   evidence_sources: []
   evidence_level: standard
   acceptance_source: user-text
   current_stage: interview-guide
   completed_stages: []
   next_step: interview-guide
   status: active
   ```
5. 使用 Glob `_ux-research/{当前日期}-{缩写}/**/*.md` 扫描已有产出，判断接续点：
   - `interviews/interview-guide-*.md` 存在 → 访谈阶段已完成
   - `tests/test-plan-*.md` 存在 → 测试阶段已完成
   - `personas/persona-*.md` 存在 → 画像阶段已完成
   - 产出文件与 state.md 冲突时以产出文件为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口 Read `meta/state.md` 确认当前进度，阶段完成后 Write 更新 `completed_stages`、`next_step` 与 `status`。

| 阶段 | 调用 | 完成标志文件 | 门控 |
|------|------|-------------|------|
| 访谈指南 | `/interview-guide $ARGUMENTS` | `interviews/interview-guide-*.md` | AskUserQuestion：继续 / 回退 / 结束 |
| 可用性测试计划 | `/usability-test-plan $ARGUMENTS` | `tests/test-plan-*.md` | AskUserQuestion：继续 / 回退 / 结束 |
| 用户画像 | `/persona-builder $ARGUMENTS` | `personas/persona-*.md` | AskUserQuestion：继续 / 回退 / 结束 |

每阶段完成后 Write 摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

使用 `AskUserQuestion` 逐维度向用户收集信息：

| 维度 | 检查要点 | 采集方式 |
|------|---------|---------|
| 目标用户 | 核心用户是谁？已有多少用研数据？ | 用户口述 |
| 核心任务 | 用户 Top 3 JTBD 是什么？ | 用户口述 |
| 已知痛点 | 当前已识别的 Top 3 可用性问题 | 用户口述 |
| 数据缺口 | 访谈/测试/定量三类数据哪些缺失？ | 引导判断 |
| 优先建议 | 下一步应先做访谈、测试还是画像？ | 基于缺口推荐 |

将结果 Write 到 `_ux-research/quick-scan-{当前日期}.md`，包含以下章节：
- `## 目标用户概要`
- `## 核心任务（JTBD）`
- `## 已知痛点`
- `## 数据缺口分析`
- `## 优先建议与下一步`

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 使用 Glob `_ux-research/*/meta/state.md` 列出所有任务的状态文件
2. 逐个 Read state.md，检查 `next_step` 是否非空（非空 = 未完成）
3. 若 state.md 缺失，用 Glob 检查产出文件推断进度；冲突时以产出为准
4. 恢复时给用户三选一：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配 UX 研究任务，再做路由 + 接续"，不是把所有请求都塞进固定管道。
访谈指南必须避免引导性问题。
可用性测试必须定义任务成功标准。
用户画像必须基于数据而非假设。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
