---
name: scan-context
description: 扫描项目代码获取被测系统的技术上下文和测试切入点
allowed-tools: Read, Write, Glob, Agent, AskUserQuestion
---

# 项目上下文扫描

目标：识别从哪进入、会发生什么、用什么信号证明、能复用什么。每次通过 Explore subagent 直读源码，不做全局缓存。

## 扫描维度（9 段）

1. **页面入口与状态迁移** — 入口、路由、守卫、重定向、各态（成功/失败/处理中/空/禁用）
2. **API 与调用链** — 前端请求、后端控制器/服务、下游调用
3. **微服务拓扑** — 涉及的服务、扇出/汇聚、MQ/gRPC
4. **权限与角色** — 可见/可操作差异、字段/按钮级权限
5. **异步与副作用** — 轮询/回调/任务、一致性窗口、Saga/补偿
6. **Feature Flag / 配置开关**
7. **数据模型与状态字段** — 实体状态机、字段约束、枚举
8. **可观察信号** — UI 文案、URL、API 请求响应、数据回显、Side Effect
9. **现有测试与可复用资产** — 已有测试、helper、fixture、asset-catalog 中的跨域资产

## 流程

1. Glob 识别技术栈
2. **Agent**（Explore, "very thorough"）按 9 段维度扫描。多服务时可并行多个 Explore
3. 结果写入 `.e2e-tests/{domain}/context/context-{slug}.md`
4. `AskUserQuestion` 确认充分性

### 落盘检查

确认以下文件已写入：
- `.e2e-tests/{domain}/context/context-*.md`（至少一个）

缺失则补写。

## 约束

- 只读扫描，不改业务代码
- 扫描走 Explore subagent，不在主上下文堆代码
- 识别不到就如实说
- 结果必须落文件（写入 `.e2e-tests/{domain}/context/`）

<IMPORTANT>
目标是"知道怎么测、能看什么信号"，不是"理解整个代码库"。
</IMPORTANT>
