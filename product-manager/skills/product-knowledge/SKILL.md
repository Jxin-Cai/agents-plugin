---
name: product-knowledge
description: 产品知识库管理——初始化、查看、添加和维护公司/产品级知识，并同步工作台状态
argument-hint: "<操作：init | view | add-decision | add-term | add-pattern | update-context>"
---

# 产品知识库管理

你现在做的是产品知识沉淀。知识库的价值不在于“存了多少”，而在于下次做需求、做 discovery、做治理分析时，不用再把同样的判断重做一遍。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

使用 Read 工具加载以下引用文件，严格遵守其中规则：

- `references/knowledge-principles.md` — 知识管理原则

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 知识库操作前先展示当前状态
- ✅ 写入前向用户确认内容
- ✅ 如果当前工作挂在某个需求目录下，尽量同步 `meta/workbench-state.md`
- 🚫 不在没有用户确认的情况下修改已有知识条目
- 🚫 不记录临时性、一次性的信息
- 📋 所有写入操作同步更新 `changelog.md`
- ⏸️ 展示菜单后停下来等用户输入

---

## Step 1: 检测知识库状态

检查 `_product_intelligence/` 是否存在。

如果不存在：
- 说明知识库用途
- 使用 `AskUserQuestion` 询问：立即初始化 / 暂不需要

如果已存在：
- 展示当前状态：
  - `product-context.md`
  - `decision-journal.md`
  - `domain-glossary.md`
  - `patterns.md`
  - `changelog.md`

如果当前上下文明显挂在某个需求目录下，也检查：
`{需求目录}/meta/workbench-state.md`

---

## Step 2: 根据参数或菜单执行操作

如果 `$ARGUMENTS` 包含明确操作：
- `init`
- `view`
- `add-decision`
- `add-term`
- `add-pattern`
- `update-context`

否则使用 `AskUserQuestion` 展示菜单：
- 初始化知识库
- 查看知识库
- 添加产品决策
- 添加领域术语
- 添加需求模式
- 更新产品上下文

**⏸️ 等待用户选择。**

---

## 操作 A: 初始化知识库

1. 创建 `_product_intelligence/`
2. 引导用户填写 `product-context.md`
3. 创建 `decision-journal.md`
4. 创建 `domain-glossary.md`
5. 创建 `patterns.md`
6. 创建 `changelog.md`

用户不确定的字段标记为 `[待补充]`，不猜测。

如果当前挂在某个需求目录下，可在该需求的 `meta/workbench-state.md` 中写入：
- `knowledge_sync.product_context: initialized`

---

## 操作 B: 查看知识库

依次展示：
1. 产品上下文
2. 最近决策摘要
3. 最近术语
4. 模式列表
5. 最近变更记录

展示完后回到菜单。

---

## 操作 C: 添加产品决策

引导用户记录：
1. 决策内容
2. 背景
3. 关联需求
4. 权衡
5. 影响范围
6. 状态

追加到 `decision-journal.md`，更新 `changelog.md`。

如果当前挂在某个需求目录下，同时更新 `meta/workbench-state.md`：
- `knowledge_sync.decision_journal: synced`
- `knowledge_sync.last_synced_items` 追加 `decision`

---

## 操作 D: 添加领域术语

引导用户记录：
1. 术语
2. 定义
3. 别名
4. 使用上下文

检查是否已有该术语：
- 若已有，向用户展示并确认是否更新
- 若没有，追加并更新 `changelog.md`

如果当前挂在某个需求目录下，同时更新 `meta/workbench-state.md`：
- `knowledge_sync.domain_glossary: synced`
- `knowledge_sync.last_synced_items` 追加 `term`

---

## 操作 E: 添加需求模式

引导用户记录：
1. 模式名称
2. 适用场景
3. 核心功能点
4. 常见陷阱
5. 参考需求

追加到 `patterns.md`，更新 `changelog.md`。

如果当前挂在某个需求目录下，同时更新 `meta/workbench-state.md`：
- `knowledge_sync.patterns: synced`
- `knowledge_sync.last_synced_items` 追加 `pattern`

---

## 操作 F: 更新产品上下文

读取当前 `product-context.md`，让用户选择更新：
- 公司与产品信息
- 目标用户
- 技术栈概要
- 已完成的需求周期
- 产品核心约束

更新后展示 diff 并确认。

如果当前挂在某个需求目录下，同时更新 `meta/workbench-state.md`：
- `knowledge_sync.product_context: synced`

---

## Step 3: 菜单

操作完成后，使用 `AskUserQuestion` 展示：
- 继续管理知识库
- 退出

**⏸️ 停下来等待用户选择。不要自动执行。**

---

## 状态同步约定

当本技能运行于某个需求目录上下文时，`meta/workbench-state.md` 可追加：

```yaml
knowledge_sync:
  decision_journal: synced | pending
  domain_glossary: synced | pending
  patterns: synced | pending
  product_context: synced | pending
  last_synced_items: [decision, term, pattern]
```

如果当前需求在澄清、PRD、复盘中产生了新术语 / 决策 / 模式，但用户尚未确认写入知识库，应标记为 `pending`。

<IMPORTANT>
知识库的职责是沉淀“以后还会用到的判断”，不是保存当前对话的流水账。
</IMPORTANT>