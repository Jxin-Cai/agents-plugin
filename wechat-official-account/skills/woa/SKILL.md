---
name: woa
description: 微信公众号运营工作台——按意图路由到内容策略、文章创作、发布到微信、粉丝分析或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 微信公众号运营工作台

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
| "内容策略 / 选题 / 排期" | strategy-only | 调用 `/content-strategy $ARGUMENTS` |
| "文章 / 创作 / 写作" | article-only | 调用 `/article-creation $ARGUMENTS` |
| "发布 / 推送 / 排版" | publish-only | 调用 `/publish-to-wechat $ARGUMENTS` |
| "分析 / 数据 / 粉丝" | analytics-only | 调用 `/subscriber-analytics $ARGUMENTS` |
| "快速检查 / 概览 / 现状" | quick-scan | → Step 3 |
| "完整流程 / 全套 或复杂需求" | full-workflow | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅内容策略 
- 仅文章 
- 仅发布 
- 仅分析 
- 完整公众号运营流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_wechat-oa/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 内容策略 | `/content-strategy $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 文章创作 | `/article-creation $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 发布到微信 | `/publish-to-wechat $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 粉丝分析 | `/subscriber-analytics $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

编排器内轻量执行各维度速览，生成精简报告到 `_wechat-oa/quick-scan-{日期}.md`。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 扫描 `_wechat-oa/` 下未完成目录
2. Read `meta/state.md`，结合产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
内容策略必须考虑平台规则和封号风险。
文章创作必须注明引用来源。
数据分析必须标注时间窗口和样本量。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
