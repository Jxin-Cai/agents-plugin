---
name: bg
description: 品牌守护者工作台——按意图路由到品牌一致性审计、语气风格审查、视觉识别检查或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 品牌守护者工作台

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
| "品牌一致性 / 品牌规范 / 品牌合规" | consistency-only | 调用 `/brand-consistency-audit $ARGUMENTS` |
| "语气 / 风格 / tone / voice" | voice-only | 调用 `/voice-tone-review $ARGUMENTS` |
| "视觉 / logo / 色彩 / VI" | visual-only | 调用 `/visual-identity-check $ARGUMENTS` |
| "快速检查 / 快扫" | quick-scan | → Step 3 |
| "完整审查 / 全面检查 或复杂需求" | full-review | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅品牌一致性 
- 仅语气 
- 仅视觉 
- 快速品牌守护检查
- 完整品牌守护流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_brand-review/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 品牌一致性审计 | `/brand-consistency-audit $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 语气风格审查 | `/voice-tone-review $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 视觉识别检查 | `/visual-identity-check $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内按以下三个维度执行速览，不调用子技能：

| 维度 | 检查动作 | 产出 |
|------|---------|------|
| 品牌一致性 | 扫描用户提供的品牌素材，列出 Logo/色彩/字体的明显偏差（≤5 项） | 偏差速览清单 |
| 语气风格 | 抽样 2-3 段核心内容，判断品牌声音是否统一 | 声音一致性速评 |
| 视觉识别 | 检查主要数字触点的视觉规范合规度（色值精确度、Logo 版本） | 视觉合规速评 |

将速览结果写入 `_brand-review/quick-scan-{日期}.md`（≤30 行）。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_brand-review/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
品牌一致性审计必须基于已记录的品牌规范，不可凭个人审美判断。
视觉识别偏差必须标注严重等级（Critical/Major/Minor）并附具体数据（色值偏差量、尺寸像素差等）。
语气偏差判定必须引用原文片段作为证据，不可仅做定性描述。
色彩合规检查必须包含 WCAG AA 级对比度验证（文字/背景 ≥ 4.5:1）。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
