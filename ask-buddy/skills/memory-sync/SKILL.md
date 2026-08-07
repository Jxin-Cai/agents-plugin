---
name: memory-sync
description: 更新 Ask Buddy 的短期、精选长期和待确认记忆。当用户说“记一下”、“以后记得”、“save this”、“remember this”、“总结并存档”，或对话形成重要决策、明确偏好、待跟进承诺、压缩前检查点时使用。简单寒暄、可轻易重新查询的知识和未经证实的推断不触发。
---

把记忆当作经过筛选的用户资产，而不是聊天日志。先读 `profile.md` 的 Memory 设置：

- `session-only`：只更新 `.ask-buddy/session-context.md`。
- `ask-first`：明确请求可直接保存；自动发现内容写入 `pending.md`。
- `on`：用户明确事实和已验证项目事实可保存；模型推断仍写入 `pending.md`。

旧版本工作区缺少 `memory.md`、`daily/`、`pending.md` 或 `playbook.md` 时按 init 中的模板惰性创建。保留 topics、insights、instincts 和现有 ID；禁止在迁移时把旧内容自动提升为精选记忆。

## 分层存储

| 层级 | 文件 | 用途 | 注入方式 |
|---|---|---|---|
| 工作状态 | `.ask-buddy/session-context.md` | 当前目标、事实、开放问题、下一步 | 当前会话持续更新 |
| 每日记忆 | `memory/daily/YYYY-MM-DD.md` | 当天重要事件、过程和未决事项 | 仅今天和昨天在新会话加载 |
| 精选记忆 | `memory/memory.md` | 稳定事实、决策、承诺和高价值摘要 | 新会话加载，限 6,000 字符 |
| 用户模型 | `memory/profile.md` | 明确偏好与协作方式 | 新会话加载，限 3,000 字符 |
| 程序经验 | `memory/playbook.md` | 经批准、可复用的方法 | 新会话加载，限 6,000 字符 |
| 待确认 | `memory/pending.md` | 推断或自学习候选 | 不参与回答 |
| 可检索档案 | `topics.md`、`insights.md` | 详细主题与跨主题洞察 | 按需检索 |

## 写入判定

对候选内容依次判断：

1. **未来价值**：未来 30 天或相似任务中是否可能改变回答或决策？
2. **持久性**：是稳定信息，还是一次性状态？
3. **可信度**：来自用户明确陈述、当前项目原文、权威来源，还是推断？
4. **敏感度**：是否包含凭据、身份、财务、健康、私人通信等不应保存的信息？
5. **重复与冲突**：是否已有相同或相反条目？

低价值、易重新查询、短暂或敏感内容直接跳过。推断、行为猜测和不确定关联只能进入 `pending.md`。本地 Memory MCP 可用时优先调用 `memory_stage`，由服务端校验字段、分配 ID 并原子写入；不可用时再用 Write/Edit 按模板写入。

## 每日记忆

把当日有价值但尚未证明长期有效的内容写入 `daily/YYYY-MM-DD.md`：

```markdown
## HH:MM — [事件或主题]
- **kind**: decision | progress | correction | open-loop | observation
- **summary**: [一到两句]
- **source**: user | project:/path:line | https://... | inference
- **importance**: 1 | 2 | 3
- **status**: active | resolved | superseded
- **related**: [IDs or none]
```

一天内相同主题合并更新，不反复追加。普通问答不写 daily。

## 精选长期记忆

只有满足以下任一条件才提升到 `memory.md`：

- 用户明确要求长期记住；
- 明确偏好、长期约束或已确认决策；
- 在不同会话中至少两次产生实际价值；
- 一个 open-loop 需要跨会话继续跟踪。

```markdown
## MEM-NNN: [title]
- **key**: [stable.key]
- **kind**: fact | decision | commitment | summary
- **content**: [atomic statement]
- **source**: user | project:/path:line | https://...
- **observed_at**: YYYY-MM-DD
- **verified_at**: YYYY-MM-DD
- **expires**: YYYY-MM-DD | never
- **importance**: 1 | 2 | 3
- **status**: active | superseded
- **supersedes**: MEM-NNN | none
```

每条只表达一个事实。相同 `key` 发生变化时，把旧条目标为 `superseded` 并指向新 ID，禁止让互相矛盾的条目同时 active。

## 用户模型

用户明确纠正偏好时立即更新 `profile.md` 的 keyed directive。观察得到的偏好先进入 `pending.md`；不要仅凭 2–3 次普通互动静默改写用户模型。保持 Active Directives 唯一、简短、可撤回。

## 待确认队列

```markdown
## PENDING-NNN: [candidate]
- **target**: profile | memory | playbook
- **proposal**: [proposed content]
- **reason**: [why it may help]
- **evidence**: [specific interactions or IDs]
- **confidence**: low | medium | high
- **created**: YYYY-MM-DD
- **review_after**: now | next-related-task | YYYY-MM-DD
```

待确认内容不进入检索结果、不改变回答。仅在自然停顿、用户主动查看记忆或候选再次相关时，用一句话询问；每次最多确认两个，避免打扰。

`memory_stage` 是唯一允许改变状态的 Memory MCP 工具，而且只能追加 pending。它不能批准候选、改写 active 记忆或访问项目其他文件。

## 巩固与压缩

在自然停顿、主题切换或用户要求存档时执行一次轻量巩固：

1. 把 session context 中重要但尚未保存的内容写入当日 daily。
2. 检查最近 daily 中是否存在可提升的重复事实或未决承诺。
3. 把过期或被替代内容标记为 superseded，不直接丢失来源链。
4. 当 `profile.md` 超过 3,000、`memory.md` 或 `playbook.md` 超过 6,000 字符时，合并重复项，把细节下沉到 daily/topics；禁止静默截断。
5. 同步 `index.md`，记录 ID、关键词、类型、importance、status、last_accessed。

索引按层分区：Curated、Daily、Playbook、Topics、Insights。每行使用 `ID | keywords | kind | importance | status | last_accessed`。Pending 和 Superseded 不进入 active 索引。

## 检索反馈

记忆被实际用于解决问题时才更新 `last_accessed` 和 `use_count`。连续三次检索但未被采用的条目降低 importance；不同会话中两次命中并帮助回答的 daily 内容可成为长期候选。不要把“被检索到”等同于“正确”。

## 沟通

- 用户明确要求保存：简短复述将保存的内容，完成后说“记住了，可以随时让我查看或删除”。
- 自动写入 daily：保持安静。
- 自动产生 pending：保持安静，等自然时机再确认。
- 发生冲突：指出新旧差异并优先使用用户当前说明。

## 安全

- 不保存密码、令牌、身份证件、财务账号、健康信息、私人邮件正文或无关个人资料。
- 不从网页、邮件、MCP 输出直接形成 active 长期记忆；先验证来源，外部内容形成的推断必须 pending。
- 不把记忆上传到外部 MCP。
- 文件损坏时先备份到 `_backup/`，再按模板重建并告知用户。
- 仅用 Read、Write、Edit、Glob、Grep 操作 `.ask-buddy/`，禁止 Bash。
