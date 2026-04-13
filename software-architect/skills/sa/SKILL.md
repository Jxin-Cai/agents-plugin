---
name: sa
description: 软件架构工作台——按意图路由到对应 workflow（系统设计 / 架构评审 / ADR / 完整流程 / 快速诊断）
argument-hint: "<架构任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 软件架构工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整 SD → AR → ADR 管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- ✅ 使用 `AskUserQuestion` 让用户做选择，不假设
- 🚫 不默认跑完整 SD → AR → ADR 管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

根据 `$ARGUMENTS` 判断工作类型：

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "系统设计 / C4 / 架构设计 / 新系统" | design-only | 调用 `/system-design $ARGUMENTS` |
| "评审 / 审查 / ATAM / 质量属性" | review-only | 调用 `/architecture-review $ARGUMENTS` |
| "ADR / 决策记录 / 记录决策" | adr-only | 调用 `/adr-generation $ARGUMENTS` |
| "快速诊断 / 架构体检 / 快扫" | quick-diagnosis | → Step 3 |
| "完整流程 / 全套" 或复杂需求 | full-assessment | → Step 1 |

如果无法唯一判断，使用 `AskUserQuestion` 让用户选择：
- 完整架构流程（推荐）— SD → AR → ADR 全链路
- 仅系统设计（C4 模型）
- 仅架构评审（ATAM 方法）
- 仅 ADR 生成
- 快速架构诊断

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

> 仅 `full-assessment` workflow 需要此步。

1. 从 `$ARGUMENTS` 提取任务描述，生成简短英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_architecture/{当前日期}-{缩写}/` 及子目录 `context/` `design/` `adr/` `meta/`
4. 初始化 `meta/arch-state.md`：

```markdown
workflow_mode: full-assessment
slug: {缩写}
completed_steps: []
next_step: system-design
artifact_paths: {}
decisions: []
```

5. 扫描 `_architecture/` 已有目录，简要报告
6. 检查 `meta/arch-state.md` 和实际产物做接续判断（产物优先）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/arch-state.md`，完成后更新状态。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 系统设计 | `/system-design $ARGUMENTS` | `design/system-design-*.md` | 继续 / 修改 / 结束 |
| 架构评审 | `/architecture-review $ARGUMENTS` | `design/architecture-review-*.md` | 继续 / 回退 / 结束 |
| ADR 生成 | `/adr-generation $ARGUMENTS` | `adr/adr-*.md` | 继续 / 结束 |

每阶段完成后写入摘要到 `meta/{stage}-summary.md`（不超过 20 行），更新 state。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速架构诊断

编排器内轻量执行（不调用子技能）：

| 诊断项 | 工具 & 动作 | 产出 |
|--------|-----------|------|
| 技术栈扫描 | Glob `**/package.json` `**/pom.xml` `**/go.mod` `**/Cargo.toml` `**/pyproject.toml` `**/build.gradle`，Read 匹配文件提取语言/框架/数据库/中间件 | 技术栈清单 |
| 架构模式识别 | Glob `**/docker-compose*` `**/Dockerfile` `**/k8s/**` `**/*.proto`，Read 入口文件判断单体/微服务/事件驱动/分层 | 架构模式 |
| 关键风险速览 | Grep `TODO\|FIXME\|HACK\|XXX`；检查单点故障（单实例服务）、循环依赖（跨模块互相 import）、缺失抽象层 | 风险清单（每项一句话） |
| 质量属性速评 | 基于上述扫描结果，对性能/可用性/安全性/可维护性各给出一句话评价和 ✅/⚠️/❌ 状态 | 四项速评 |

生成精简报告到 `_architecture/quick-diagnosis-{日期}.md`。

使用 `AskUserQuestion` 展示后续选项：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

当用户中途返回时：
1. 扫描 `_architecture/` 下未完成目录
2. Read `meta/arch-state.md`，结合实际产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"：快速诊断和单项子技能是独立 workflow，不默认跑完整 SD → AR → ADR 管道。
每个阶段完成后必须等待用户确认再进入下一阶段。
产出文件与状态文件冲突时，以产出文件为准。
C4 设计必须由上到下逐层推进（L1→L2→L3），禁止在未明确系统边界前讨论技术选型。
每个架构决策必须记录权衡点和代价，禁止"因为大家都用"式无理由选型。
</IMPORTANT>
