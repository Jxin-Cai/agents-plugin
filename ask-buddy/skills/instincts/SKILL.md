---
name: instincts
description: 用户要求查看行为偏好，或明确纠正回答方式、表达长期协作要求时使用。触发包括“我的习惯”、“你了解我吗”、“以后先给结论”、“别再问多个问题”、"my patterns"、"I prefer"、"never do that again"。把行为偏好统一写入 profile 或 pending，不维护第二套生效规则。
---

把行为偏好视为用户模型的一部分。唯一有效来源是 `profile.md` 中的 `PREF-NNN` directive；推断型偏好只进入统一 pending 队列。

## 明确指令

用户明确说“以后请……”“不要再……”或“我偏好……”时：

1. 提炼成一个祈使式、可执行 directive。
2. 调用 `memory_stage`，设置 `target: profile`、稳定 `subject`、`source: user` 和具体 evidence。
3. 用户当前话语已明确要求保存时，可在同一轮调用 `learning_decide approve`，无需再次询问。
4. 新旧 directive 冲突时展示差异，并用 `supersedes` 明确替换旧 `PREF-NNN`。

## 推断偏好

只有跨会话重复出现或用户纠正过的模式才可成为候选。调用 `memory_stage` 暂存，保持 inactive，等用户审核。单次普通选择、情绪、主题兴趣和弱观察不保存。

## 查看与撤回

用户询问“你了解我什么”时，展示 active profile directives 与 pending profile 候选，分清已生效和待确认。用户否认某条偏好时立即 supersede 或删除对应 `PREF-NNN`，并清理同义 pending。

## 兼容旧文件

旧 `.ask-buddy/memory/instincts.md` 仅作为迁移来源，不再直接影响回答。若其中 Confirmed 条目仍有价值，先转换成 profile 候选并让用户审核；不要继续累计分数或创建新的 INST ID。

## 边界

- 不记录身份、健康、财务、联系方式或私人生活画像。
- 不把焦点主题自动解释为稳定偏好。
- 不让同一 directive 同时存在于 profile、pending 和 legacy instincts。
