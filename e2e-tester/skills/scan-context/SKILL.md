---
name: scan-context
description: 扫描当前项目代码获取被测系统的技术上下文和测试切入点。当在 /e2e 流程的扫描阶段，或用户要求"扫描代码"、"分析项目"时触发。
allowed-tools: Read, Glob, Grep, Agent, AskUserQuestion
---

# 项目上下文与测试切入点扫描

扫描目标是为后续测试提供四类信息：从哪里进入（入口、路由、权限）、会发生什么（状态迁移、调用链、异步副作用）、用什么证明（UI / API / Data / Side Effect 信号）、能复用什么（已有测试、helper、fixture）。

---

## 扫描清单

### 页面入口与状态迁移
- 入口页面、导航路径、路由守卫、重定向
- 成功/失败/处理中/空态/禁用态

### API 与服务调用链
- 前端发起哪些请求、后端控制器/服务
- 是否继续调用其他服务 / MQ / 任务系统

### 权限与角色
- 哪些角色可见/可操作、字段级/按钮级权限差异

### 异步与副作用
- 轮询、回调、异步任务
- 消息、导出、下载、库存、审批、日志

### 可观察信号
- UI 文案/组件状态、URL/路由变化、API 请求/响应
- 数据回显/列表反查/状态字段、Side effect（通知、导出文件）

### 复用资产
- 已有测试文件、login helper、data factory、fixture / mock 模板

## 扫描边界

- 每个任务 **≤20 个文件**
- 优先定义文件，不先陷入实现细节
- 不扫描 `node_modules/`、`vendor/`、`.git/`、`dist/`、`build/`

---

## 执行流程

### Step 1: 识别技术栈

Glob 扫描 `package.json`、`pom.xml`、`go.mod`、`playwright.config.*` 等，识别应用类型并据此调整扫描关注点：

| 应用类型 | 重点关注 |
|---------|---------|
| SPA (React/Vue/Angular) | 路由切换、状态管理、异步加载 |
| SSR (Next.js/Nuxt) | 水合时机、API 路由、中间件 |
| 传统 MPA | 表单提交、页面跳转、Session 管理 |
| 后台管理系统 | 权限控制、CRUD 流程、批量操作 |
| 移动端 H5 | 响应式布局、触摸事件、WebView 兼容 |

### Step 2: 用 Explore agent 扫描被测功能

使用 **Agent** 工具启动探索型 agent（`subagent_type: "Explore"`），将被测功能关键词和扫描清单传入 prompt。

prompt 要求：
- 围绕 **{被测功能关键词}** 扫描当前项目
- 按扫描清单的 7 段输出 Markdown：页面入口与状态迁移、API 与服务调用链、权限与角色、异步与副作用、Feature flag / 配置开关、数据模型与状态字段、现有测试与可复用资产
- 约束：最多读取 20 个文件；不读取 node_modules/, vendor/, .git/, dist/, build/
- 扫描深度指定为 `"very thorough"`

### Step 3: 沉淀上下文摘要

将扫描结果写入 `.e2e-tests/{domain}/context/context-{slug}.md`，结构：技术栈 → 功能入口与状态迁移 → 调用链与依赖 → 权限与角色 → 可观察信号 → 现有测试资产 → 测试建议。

### Step 4: 用户确认

使用 **AskUserQuestion** 确认扫描结果是否充分。

扫描充分的标准：能说清从哪开始、到哪结束、状态如何变化、用什么信号证明、哪些依赖需要 Mock、有什么可复用。

**⏸️ 等待用户确认后结束。**

---

## 约束

1. **只读扫描** — 不修改业务代码
2. **代码扫描必须走 Explore agent** — 不在主上下文中堆积大量代码
3. **识别不造** — 扫不到就如实说
4. **扫描结果必须落文件** — 沉淀到 `context/`

<IMPORTANT>
目标是"知道怎么测、能看什么信号"，不是"理解整个代码库"。
</IMPORTANT>
