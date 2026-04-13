---
name: discovery-product
description: 发现式产品管理——澄清问题、证据、假设和实验，判断是否进入交付阶段
argument-hint: "<问题空间、机会或需求方向>"
---

# 发现式产品管理

你现在做的是 discovery，不是写方案。先和用户一起把问题说清、把证据摆出来、把假设挑出来，再决定这件事值不值得进入交付。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

使用 Read 工具加载：
- `references/discovery-principles.md`
- `assets/discovery-template.md`

如从需求目录进入，也读取：
- `{需求目录}/meta/workbench-state.md`
- `{需求目录}/domain/context-*.md`
- `{需求目录}/domain/clarified-*.md`

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先定义问题和证据，再谈方案
- ✅ 区分事实、判断、假设和实验
- ✅ 如果证据不足，要显式说明不确定性
- 🚫 不把 discovery 直接写成功能方案
- ⏸️ 每个关键阶段都停下来等用户确认
- 💾 用户确认后才保存

---

## 目录约定

- 独立运行：`.product-manager/discovery/{当前日期}-{任务简写}/`
- 作为需求型维度运行：`{需求目录}/discovery/`

---

## Step 1: 定义问题空间

澄清：
- 目标用户是谁？
- 他们在什么场景下遇到什么问题？
- 当前有什么证据表明问题存在？
- 如果问题不解决，会造成什么影响？

## Step 2: 提炼机会与假设

整理：
- 问题陈述
- 机会空间
- 关键假设
- 每个假设的风险等级

## Step 3: 设计验证方式

为关键假设设计验证：
- 访谈 / 调研
- 数据验证
- 轻量实验
- 假门 / 原型 / MVP

明确：
- 想验证什么
- 看到什么结果算支持
- 看到什么结果算不支持

## Step 4: 决策门

引导用户做结论：
- 进入交付（推荐做 PRD）
- 继续验证
- 暂不推进

## Step 5: 用户确认与保存

保存到：
- 独立运行：`.product-manager/discovery/{当前日期}-{任务简写}/discovery-{日期}.md`
- 需求型维度：`{需求目录}/discovery/discovery-{日期}.md`

如果是需求型维度，同时更新 `meta/workbench-state.md`：
- `completed_steps` 追加 `discovery-product`
- `artifact_paths.discovery`
- `next_recommended_step`

<IMPORTANT>
本技能的目标是帮助用户判断“是否值得进入交付”，而不是替代 PRD。
</IMPORTANT>