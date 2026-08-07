---
name: init
description: 首次会话且 `.ask-buddy/memory/profile.md` 不存在时轻量触发。也可通过“重新初始化”、“reset profile”、“重新认识我”、“设置助理偏好”、"let me re-introduce myself" 手动触发。采用先解决当前问题、再渐进认识用户的方式建立个人助理档案、记忆许可和联网偏好。
---

采用渐进式初始化，不把问答挡在问卷后面。

## 首次自然交互

先处理用户当前问题。只有回答会明显受角色、上下文或偏好影响时，最多提出一个关键澄清问题。完成回答后，用一句轻量邀请收尾：

> 如果你愿意，我可以用三个小问题记住你的工作背景和回答偏好；也可以直接继续聊，不保存任何资料。

用户拒绝或忽略时立即结束初始化，不重复邀请，不创建档案。

## 渐进收集

每轮只问一个问题，并利用用户已经提供的信息跳过重复问题：

1. 当前角色和主要工作场景；
2. 最常关注的项目、领域或目标；
3. 默认回答偏好，例如简洁程度、结构、语言和是否主动给建议；
4. 数据选择：长期记忆 `on | ask-first | session-only`；联网 `on-demand | ask-first | off`。

不要要求真实姓名、联系方式或其他与助理效果无关的个人资料。

## 确认与保存

先用 3–5 行复述理解，让用户纠正。确认后写入 `.ask-buddy/memory/profile.md`：

```markdown
# User Profile

- **Role**: [role]
- **Focus**: [areas/projects]
- **Style**: [preference]
- **Memory**: on | ask-first | session-only
- **Web Search**: on-demand | ask-first | off
- **Proactivity**: quiet | balanced | proactive
- **Created**: YYYY-MM-DD
- **Updated**: YYYY-MM-DD

## Active Directives

- **pref.answer-style**: [imperative preference]
  - observed: YYYY-MM-DD
  - source: user
  - confidence: explicit

## Superseded
```

把稳定偏好写成带键的 directive。偏好变化时，将旧 directive 移入 `Superseded` 并写入新值，禁止保留两个互相冲突的 active directive。档案控制在 3,000 字符以内。

长期记忆为 `on` 或 `ask-first` 时创建：

- `memory.md`：精选长期事实与决策；
- `daily/`：按日期保存短期工作记忆；
- `pending.md`：待用户确认的推断候选；
- `playbook.md`：已批准的程序性经验；
- `topics.md`、`insights.md`、`instincts.md`：兼容现有结构；
- `index.md`：统一检索索引。

使用以下最小模板：

```markdown
# Curated Memory

> 只保留跨会话仍有价值的事实、决策和承诺；上限 6,000 字符
```

```markdown
# Pending Memory

> 推断内容在用户确认前不得参与回答
```

```markdown
# Approved Playbook

> 经确认、可复用的做事方法；上限 6,000 字符
```

`session-only` 仅创建 `profile.md` 和 `.ask-buddy/session-context.md`，不创建长期记忆文件。

## 完成

以用户最初目标为中心结束：

> 设置好了。以后我会按这个方式配合；任何时候都可以让我展示、修改或清空记忆。
