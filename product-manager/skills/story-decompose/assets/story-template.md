# Story 分解产出模板

---
type: stories
version: 1
source_prd: {{PRD 文件路径}}
created: {{日期}}
slug: {{需求简写}}
epic_count: {{数字}}
story_count: {{数字}}
ac_count: {{数字}}
---

# Story 清单: {{项目名称}}

> 来源 PRD: {{PRD 文件名}}

## 分解概览

| 指标 | 数值 |
|------|------|
| Epic 数 | {{N}} |
| Story 数 | {{M}} |
| 验收标准数 | {{K}} |
| P0 Story | {{a}} |
| P1 Story | {{b}} |
| P2 Story | {{c}} |

---

## Epic 1: [模块名] — [价值描述]

> 来源：PRD 功能模块 [模块名]，功能点 F1, F2, F5

### Story 1-1: [简短标题]

**用户故事：** 作为 [角色]，我想要 [能力]，以便 [价值]

**来源：** PRD F1

**验收标准：**
- AC1: Given [前置条件], When [操作], Then [预期结果]
- AC2: Given [异常条件], When [操作], Then [错误处理]
- AC3: Given [边界条件], When [操作], Then [边界行为]

**Story Points 提示：** [S/M/L] — [判断依据]

**优先级：** P0

---

### Story 1-2: [简短标题]

...

---

## Epic 2: [模块名] — [价值描述]

...

---

## 追溯矩阵

| PRD 功能点 | 对应 Story | 优先级 |
|-----------|-----------|--------|
| F1 | Story 1-1 | P0 |
| F2 | Story 1-2, Story 1-3 | P0 |
| F3 | Story 2-1 | P1 |

## INVEST 检验结果

| Story | I | N | V | E | S | T | 结果 |
|-------|---|---|---|---|---|---|------|
| 1-1 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 通过 |
| 1-2 | ✅ | ✅ | ✅ | ✅ | ⚠️ | ✅ | 待调整：粒度偏大 |
