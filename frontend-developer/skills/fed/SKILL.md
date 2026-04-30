---
name: fed
description: 前端审查工作台——先装配任务，再按意图路由到组件审查 / 性能检查 / 响应式审计 / 快速扫描 / 完整审查 / 自定义组合
argument-hint: "<审查任务描述或目标组件/页面路径>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(mkdir*|wc*)", "AskUserQuestion", "Skill"]
---

# 前端审查工作台

用户传入的参数：`$ARGUMENTS`

先装配前端审查任务，再带他进入对应 workflow。不是所有需求都需要走完整 组件审查 → 响应式审计 → 性能检查 管道。

**入口纪律**：除非用户明确点名 `/component-review`、`/responsive-audit`、`/performance-check`，或明确要求“只做组件审查 / 只做响应式 / 只做性能检查 / 只做快速扫描”，否则都先走 `/frontend-developer:fed` 入口。像“帮我看下这个页面组件结构”“前端发版前过一遍”“看看性能和适配风险”这类泛化请求，一律先完成任务装配，再决定 workflow。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先装配任务卡，再识别 workflow 类型
- ✅ 使用 `AskUserQuestion` 让用户做选择，不假设
- ✅ 所有审查结论基于代码事实和行业标准，绝不凭空臆断
- 🚫 不默认跑完整 组件 → 响应式 → 性能 管道
- 🚫 不在入口全量加载所有 references
- 🚫 绝不在没有读取实际代码的情况下给出审查结论
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 任务装配与 Workflow 路由

### 显式快路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "组件 / Props / 状态管理 / 架构审查 / 拆分" | component-only | 调用 `/component-review $ARGUMENTS` |
| "性能 / Core Web Vitals / LCP / INP / CLS / bundle" | performance-only | 调用 `/performance-check $ARGUMENTS` |
| "响应式 / 断点 / 移动端 / 适配 / 多端" | responsive-only | 调用 `/responsive-audit $ARGUMENTS` |
| "快速扫描 / 快扫 / 快速检查 / 概览" | quick-scan | → Step 3 |
| "继续上次前端任务 / 恢复任务" | resume | 优先进入断点恢复 |
| "完整审查 / 全套 / 全面审查" 或复杂需求 | full-audit | → Step 1 |
| 混合需求（如“组件和性能”） | custom | → Step 4 |

### 任务装配

意图不明确时，用 `AskUserQuestion` 一次性补齐最小任务卡：
- `task_type`：component-audit / responsive-audit / performance-audit / full-audit / quick-scan / custom
- `target_scope`：页面 / 组件 / 路由 / 模块
- `acceptance_source`：user-text / markdown / issue / none
- `evidence_level`：light / standard / strict
- `entry_intent`：用户原话
- `current_stage`：当前阶段
- `completed_stages`：已完成阶段
- `next_step`：下一步动作

workflow 确定后，先向用户宣告本次场景、目标和执行链路，再进入后续步骤。

---

## Step 1: 完整流程初始化

> 仅 `full-audit` workflow 需要此步。

1. 从 `$ARGUMENTS` 提取任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `dashboard-refactor`、`login-page`）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_frontend-review/{当前日期}-{缩写}/` 及子目录 `context/` `components/` `responsive/` `performance/` `meta/`
4. 初始化 `meta/review-state.md`：

```markdown
workflow_mode: full-audit
task_type: full-audit
entry_intent: {用户原话}
target_scope: {页面/组件/模块}
acceptance_source: none
evidence_level: standard
current_stage: component-review
completed_stages: []
next_step: component-review
last_updated: {YYYY-MM-DD}
last_artifact: 
```

5. 扫描 `_frontend-review/{目录}/components/`、`responsive/`、`performance/` 中的产物文件，判断接续点——产物存在则跳过对应阶段
6. 重新 Read `meta/review-state.md`，产物与状态冲突时以产物为准

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/review-state.md`，完成后更新状态。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 组件架构审查 | `/component-review $ARGUMENTS` | `components/component-review-*.md` | 继续 / 修改 / 结束 |
| 响应式审计 | `/responsive-audit $ARGUMENTS` | `responsive/responsive-audit-*.md` | 继续 / 回退 / 结束 |
| 性能检查 | `/performance-check $ARGUMENTS` | `performance/performance-check-*.md` | 继续 / 结束 |

每阶段完成后写入摘要到 `meta/{stage}-summary.md`（不超过 20 行），更新 state。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速扫描

编排器内轻量执行（不调用子技能）：

1. **技术栈扫描**：Read 项目根目录 `package.json`，提取 `dependencies` 和 `devDependencies` 中的框架（react / vue / svelte / angular）、构建工具（vite / webpack / next / nuxt）、CSS 方案（tailwind / styled-components / sass）、状态管理（redux / zustand / pinia / mobx）
2. **组件概览**：用 Glob 扫描 `src/**/*.{tsx,jsx,vue,svelte}` 获取组件文件列表，用 Bash `wc -l` 统计各文件行数，列出总数、平均行数、超过 200 行的大组件清单
3. **响应式速评**：用 Grep 搜索 `@media` 和 `@container` 查询，统计断点定义位置和数量；检查媒体查询方向（`min-width` vs `max-width`），判断是否统一
4. **性能速评**：Read 构建配置文件（`vite.config.*` / `next.config.*` / `webpack.config.*`），检查代码分割配置；用 Grep 搜索 `import(` 统计动态导入数量；Read `package.json` 检查是否存在已知大依赖（moment / lodash / chart.js）

生成精简报告到 `_frontend-review/quick-scan-{日期}.md`。

使用 `AskUserQuestion` 展示后续选项：深入某项 / 进入完整流程 / 结束。

---

## Step 4: 自定义组合

> 仅 `custom` workflow 需要此步。

1. 使用 `AskUserQuestion` 让用户勾选要执行的阶段（组件审查 / 响应式审计 / 性能检查）
2. 按用户选择的顺序依次调用对应子技能
3. 每个子技能完成后等待确认再执行下一个

---

## 断点恢复

当用户中途返回时：
1. 扫描 `_frontend-review/` 下未完成目录
2. 先 Read `meta/review-state.md`，再核对 `components/`、`responsive/`、`performance/` 产物
3. 产物优先于状态文件；旧任务缺字段时，续跑时补齐，不阻塞执行
4. 使用 `AskUserQuestion`：从断点继续 / 从某阶段重开 / 重新开始

<IMPORTANT>
工作台的职责是"先装配前端审查任务，再做路由 + 接续"，不是把所有请求都塞进 组件 → 响应式 → 性能 管道。
快速扫描和单项子技能是独立 workflow，不经过完整管道。
每个阶段完成后必须等待用户确认再进入下一阶段。
产出文件与状态文件冲突时，以产出文件为准。
绝不在没有 Read 实际源代码文件的情况下给出审查结论——所有发现必须附带文件路径和行号。
组件审查必须覆盖四个维度（层级职责 / Props 接口 / 状态管理 / 可复用性），缺一视为未完成。
性能问题必须量化预估影响（kB / ms 级别），禁止“减少 JS 大小”等无量化结论。
响应式审计必须从 320px 起覆盖全断点范围，不可只检查桌面端。
</IMPORTANT>
