# 发布与同步原则

## 字段映射规范

### Story 模板 → Jira Issue 字段

| Story 模板字段 | Jira Issue 字段 | 说明 |
|---------------|----------------|------|
| `## Epic N: [模块名] — [价值描述]` | Epic summary | 完整保留"模块名 — 价值描述"格式 |
| Epic 下所有 Story 的概览 | Epic description | 汇总各 Story 标题和优先级 |
| `### Story N-M: [标题]` | Story summary | 保留简短标题 |
| `**用户故事：**` | Story description 首段 | "作为…我想要…以便…" |
| `**验收标准：**` AC1..ACn | Story description 后段 | Given/When/Then 格式 |
| `**来源：** PRD F#` | Story description 附注 | 追溯信息 |
| `**优先级：** P0/P1/P2` | priority 字段 | 按映射表转换 |
| `**Story Points 提示：** S/M/L` | story_points 字段（如有） | 可选，S=1, M=3, L=5 |

### 优先级映射

| 本地优先级 | Jira Priority |
|-----------|--------------|
| P0 | Highest |
| P1 | High |
| P2 | Medium |
| P3 | Low |
| 未标注 | Medium（默认） |

## 发布流程规则

### 幂等性

- 发布前检查 `meta/jira-sync.yaml` 是否已存在
- 如果已发布，提示用户选择：增量同步 / 全量重新发布 / 取消
- 同一个 Story 不重复创建（通过 jira-sync.yaml 中的 local_id → jira_key 映射判断）

### 发布顺序

1. 先创建所有 Epic（因为 Story 需要 parent 引用）
2. 拿到 Epic key 后，创建 Story 并设置 parent
3. 可选：将 PRD 文档作为附件上传到首个 Epic

### 错误处理

- 单个 issue 创建失败不阻断整体流程
- 失败的 issue 记录在 jira-sync.yaml 中标记 `status: failed`
- 重跑时只处理 failed 和未发布的 issue

## jira-sync.yaml 格式

```yaml
project_key: SCRUM
published_at: 2026-04-14T18:00:00+08:00
source_file: stories/stories-2026-04-14.md
source_hash: <md5>
epics:
  - local_id: "Epic 1"
    jira_key: SCRUM-10
    summary: "用户认证模块 — 安全登录体验"
    stories:
      - local_id: "Story 1-1"
        jira_key: SCRUM-11
        summary: "邮箱密码登录"
        source_hash: <md5>
        last_synced: 2026-04-14T18:00:00+08:00
        status: synced
prd_attachment:
  jira_key: SCRUM-10
  file: prd/prd-auth-2026-04-14.md
  hash: <md5>
```

## 同步规则

### 变更检测

- 对每个 Story 块（从 `### Story N-M` 到下一个 `### Story` 或 `## Epic`）计算 md5
- 与 jira-sync.yaml 中记录的 source_hash 对比
- 仅推送有变更的 Story

### 同步内容

- summary：如果 Story 标题变了
- description：用户故事 + 验收标准 + 来源的完整重组

### 状态推断

不做自动状态推断。状态流转仅在用户明确请求时执行（通过 `/req-transition`）。避免因本地文件状态与 Jira 不一致导致意外流转。
