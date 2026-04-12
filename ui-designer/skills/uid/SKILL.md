---
name: uid
description: UI 设计评审工作台——按意图路由到对应 workflow（视觉快扫 / 视觉审计 / 设计系统评审 / 原型反馈 / 完整流程 / 自定义组合）
argument-hint: "<评审任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# UI 设计评审工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整 VA → DSR → PF 管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- ✅ 使用 `AskUserQuestion` 让用户做选择，不假设
- 🚫 不默认跑完整 VA → DSR → PF 管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

根据 `$ARGUMENTS` 判断工作类型：

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "快扫 / 快速检查 / 简单看看 / 速览" | visual-quick-scan | → Step 3 |
| "视觉审计 / Gestalt / Nielsen / 启发式 / 视觉评估" | visual-audit-only | 调用 `/visual-audit $ARGUMENTS` |
| "设计系统 / Token / 组件一致性 / DS" | design-system-only | 调用 `/design-system-review $ARGUMENTS` |
| "原型 / 交互 / 流程 / 走查 / 用户旅程" | prototype-only | 调用 `/prototype-feedback $ARGUMENTS` |
| "完整流程 / 全套 / 完整评审" 或复杂需求 | full-audit | → Step 1 |
| 用户明确指定组合（如"视觉+原型"） | custom | → Step 4 |

如果无法唯一判断，使用 `AskUserQuestion` 让用户选择：
- 完整评审流程（推荐）— VA → DSR → PF 全链路
- 仅视觉审计（Gestalt + Nielsen 启发式）
- 仅设计系统评审（Token + 组件一致性）
- 仅原型反馈（交互走查 + 用户旅程）
- 视觉快扫（轻量级快速检查）
- 自定义组合（选择要执行的阶段）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

> 仅 `full-audit` workflow 需要此步。

1. 从 `$ARGUMENTS` 提取评审任务描述，生成简短英文缩写（2-4 词，连字符连接，如 `homepage-redesign`、`checkout-flow`）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_design-review/{当前日期}-{缩写}/` 及子目录 `context/` `visual/` `design-system/` `prototype/` `meta/`
4. 初始化 `meta/design-review-state.md`：

```markdown
workflow_mode: full-audit
slug: {缩写}
completed_steps: []
next_step: visual-audit
artifact_paths: {}
decisions: []
```

5. 扫描 `_design-review/` 已有目录，简要报告
6. 检查 `meta/design-review-state.md` 和实际产物做接续判断（产物优先）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/design-review-state.md`，完成后更新状态。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 视觉审计 | `/visual-audit $ARGUMENTS` | `visual/visual-audit-*.md` | 继续 / 修改 / 结束 |
| 设计系统评审 | `/design-system-review $ARGUMENTS` | `design-system/ds-review-*.md` | 继续 / 回退 / 结束 |
| 原型反馈 | `/prototype-feedback $ARGUMENTS` | `prototype/prototype-feedback-*.md` | 继续 / 结束 |

每阶段完成后写入摘要到 `meta/{stage}-summary.md`（不超过 20 行），更新 state。

**⏸️ 每步等待用户确认。**

---

## Step 3: 视觉快扫

编排器内轻量执行（不调用子技能）：

1. **视觉层次速评**：斜视测试 + 5 秒测试，判断信息优先级是否合理
2. **Nielsen 关键三项速查**：H1 系统状态可见性 / H5 错误预防 / H8 审美与极简设计
3. **Gestalt 关键两项速查**：接近性（分组是否合理）/ 图底关系（焦点是否清晰）
4. **无障碍基线**：对比度 4.5:1 / 触摸目标 44px / 颜色非唯一载体

生成精简报告到 `_design-review/quick-scan-{日期}.md`，使用以下模板：

```markdown
# 视觉快扫报告

**日期**：{YYYY-MM-DD}
**评审对象**：{页面/设计稿描述}

## 视觉层次
| 测试 | 结果 | 说明 |
|------|------|------|
| 斜视测试 | ✅/⚠️/❌ | {最重要元素是否突出？分组是否清晰？} |
| 5 秒测试 | ✅/⚠️/❌ | {页面用途是否可识别？主操作入口是否可发现？} |

## Nielsen 关键三项
| 启发式 | 评级(0-4) | 发现 |
|--------|-----------|------|
| H1 系统状态可见性 | {N} | {具体问题或"无明显问题"} |
| H5 错误预防 | {N} | {具体问题或"无明显问题"} |
| H8 审美与极简设计 | {N} | {具体问题或"无明显问题"} |

## Gestalt 关键两项
| 原则 | 评级(✅/⚠️/❌) | 发现 |
|------|----------------|------|
| 接近性 | {评级} | {分组是否合理？} |
| 图底关系 | {评级} | {焦点是否清晰？} |

## 无障碍基线
| 检查项 | 标准 | 结果 |
|--------|------|------|
| 文本对比度 | >= 4.5:1 | ✅/❌ |
| 触摸目标 | >= 44x44px | ✅/❌/N/A |
| 颜色载体 | 颜色非唯一信息手段 | ✅/❌ |

## 结论
- **最需关注**：{1-2 个最突出问题}
- **整体印象**：{一句话总结}
```

使用 `AskUserQuestion` 展示后续选项：深入某项 / 进入完整流程 / 结束。

---

## Step 4: 自定义组合

1. 使用 `AskUserQuestion` 让用户勾选要执行的阶段：
   - 视觉审计
   - 设计系统评审
   - 原型反馈
2. 按用户选择的顺序依次调用对应子技能
3. 每阶段完成后等待确认再进入下一阶段

---

## 断点恢复

当用户中途返回时：
1. 扫描 `_design-review/` 下未完成目录
2. Read `meta/design-review-state.md`，结合实际产物推断进度
3. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进 VA → DSR → PF 管道。视觉快扫和单项子技能是独立 workflow，不经过完整管道。
每个阶段完成后必须等待用户确认再进入下一阶段。
产出文件与状态文件冲突时，以产出文件为准。
绝不在没有看到设计产出的情况下给出评审意见。
所有评审意见必须关联到具体原则（Nielsen / Gestalt / WCAG / 设计系统规范），不做无依据的主观评价。
</IMPORTANT>
