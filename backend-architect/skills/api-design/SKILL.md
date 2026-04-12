---
name: api-design
description: RESTful API 契约设计——资源建模、端点规划、错误码体系、版本策略
argument-hint: "<需求描述或功能模块>"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(ls*|find*)", "AskUserQuestion"]
---

# API 设计

用户传入的参数：`$ARGUMENTS`

**核心心态：** API 是系统间的契约，不是函数调用的 HTTP 包装。好的 API 设计让消费者不需要看实现就能正确使用。

---

## 加载引用

使用 Read 工具加载以下引用文件，严格遵守其中所有规则：

- `references/api-design-principles.md` — 资源建模、HTTP 语义、错误处理
- `references/api-crosscutting-principles.md` — 版本控制、分页、幂等性、安全设计

---

## 前置条件

确定当前工作目录：检查 `_backend-arch/` 下最近创建的日期目录。若无，询问用户并创建。

加载以下上下文（如果存在）：
- `{工作目录}/context/**` — 需求背景和约束条件
- 当前对话中已有的讨论

---

## Step 1: 识别核心资源

如果 `$ARGUMENTS` 非空，以此作为需求的初始输入。

引导用户识别系统中的核心资源（名词，不是动词）：

| 维度 | 需回答 |
|------|--------|
| 业务实体 | 系统管理的核心对象是什么？（用户、订单、商品、文章...） |
| 关系梳理 | 实体之间的关系？（一对一、一对多、多对多） |
| 生命周期 | 每个资源的状态流转？（草稿 → 已发布 → 已归档） |
| 归属关系 | 资源的层级关系？（组织 > 部门 > 成员） |

向用户展示资源清单和关系图（文本格式），确认是否完整。

**⏸️ 等待用户确认后继续。**

## Step 2: 端点设计

为每个核心资源设计 CRUD 端点，遵循 RESTful 规范：

```
资源: {资源名}
├── GET    /api/v1/{resources}          — 列表查询（支持分页、筛选、排序）
├── POST   /api/v1/{resources}          — 创建资源
├── GET    /api/v1/{resources}/{id}     — 获取单个资源
├── PUT    /api/v1/{resources}/{id}     — 全量更新
├── PATCH  /api/v1/{resources}/{id}     — 部分更新
├── DELETE /api/v1/{resources}/{id}     — 删除资源
└── 业务操作:
    ├── POST /api/v1/{resources}/{id}/actions/{action}  — 状态变更
    └── GET  /api/v1/{resources}/{id}/{sub-resources}   — 子资源查询
```

对每个端点明确：请求参数、响应结构、HTTP 状态码（含错误状态码）。

**⏸️ 逐个资源向用户展示，等待确认后继续下一个。**

## Step 3: 错误码体系

设计统一的错误响应格式和业务错误码：

```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "用户可读的错误描述",
    "details": [{"field": "email", "reason": "INVALID_FORMAT", "message": "邮箱格式不正确"}],
    "request_id": "req-uuid"
  }
}
```

引导用户定义：HTTP 状态码与业务错误码的映射关系、通用错误码、业务特定错误码。

**⏸️ 等待用户确认后继续。**

## Step 4: 横切关注点

与用户讨论并确定以下横切关注点的策略：

| 关注点 | 需决策 |
|--------|--------|
| 版本控制 | URL 路径（/v1/）还是 Header（Accept-Version）？ |
| 认证方式 | JWT / OAuth 2.0 / API Key？Token 刷新策略？ |
| 分页策略 | 游标分页还是偏移分页？默认页大小？ |
| 限流策略 | 全局限流 / 用户级限流？限流后的响应（429）？ |
| 幂等性 | 哪些操作需要幂等性保证？Idempotency-Key Header？ |
| 缓存策略 | 哪些端点可缓存？ETag / Cache-Control 策略？ |

**⏸️ 等待用户逐项确认。**

## Step 5: 保存产出

将 API 设计文档保存到 `{工作目录}/api/api-design-{日期}.md`

内容包括：资源清单和关系图、完整端点列表（含请求/响应结构）、错误码体系、横切关注点决策记录。

## Step 6: 菜单

使用 `AskUserQuestion` 工具向用户展示以下选项：

产出摘要：[N] 个核心资源，[M] 个 API 端点，[K] 个业务错误码。横切关注点已决策 [X]/6 项。

- **进入数据库建模（推荐）** — 基于已识别的资源进行数据库 ER 模型设计
- **补充 API 端点** — 如果感觉有遗漏的资源或操作
- **直接进行可扩展性评审** — 如果数据库模型已有现成方案

**⏸️ 停下来等待用户选择。不要自动执行。**

<IMPORTANT>
本技能完成后，展示菜单并等待用户选择下一步。不要自动执行后续技能。
每个端点必须同时定义正常响应和错误响应（含 HTTP 状态码 + 业务错误码），只有 happy path 的设计不合格。
</IMPORTANT>
