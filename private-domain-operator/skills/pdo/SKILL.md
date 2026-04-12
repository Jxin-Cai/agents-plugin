---
name: pdo
description: 私域运营工作台——按意图路由到企微生态搭建、社群运营、用户生命周期、全链路转化或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 私域运营工作台

用户传入的参数：`$ARGUMENTS`

先判断用户此刻要完成的工作，再带他进入对应 workflow。不是所有需求都需要走完整管道。

---

## 强制执行规则

- ✅ 始终用中文与用户沟通
- ✅ 先识别 workflow 类型，再进入对应流程
- 🚫 不默认跑完整管道
- 🚫 不在入口全量加载所有 references
- ⏸️ 每个阶段完成后等待用户确认

---

## Step 0: 意图识别与 Workflow 路由

| 意图信号 | Workflow | 动作 |
|----------|----------|------|
| "企微 / 企业微信 / 搭建" | wecom-only | 调用 `/wecom-ecosystem-setup $ARGUMENTS` |
| "社群 / 社区 / 运营" | community-only | 调用 `/community-operations $ARGUMENTS` |
| "生命周期 / 留存 / 召回" | lifecycle-only | 调用 `/user-lifecycle $ARGUMENTS` |
| "转化 / 漏斗 / 成交" | conversion-only | 调用 `/conversion-funnel $ARGUMENTS` |
| "完整策略 / 全套 或复杂需求" | full-strategy | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅企微 
- 仅社群 
- 仅生命周期 
- 仅转化 
- 完整私域运营流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_private-domain/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 使用 Glob 扫描 `_private-domain/{当前日期}-{缩写}/` 下已有文件，依次检查 `ecosystem/scrm-blueprint.yaml`、`community/community-playbook.md`、`lifecycle/lifecycle-automation.py`、`funnel/funnel-strategy.md`，存在即标记对应阶段为已完成（产物优先于 state.md）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 企微生态搭建 | `/wecom-ecosystem-setup $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 社群运营 | `/community-operations $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 用户生命周期 | `/user-lifecycle $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |
| 全链路转化 | `/conversion-funnel $ARGUMENTS` | 对应产出文件 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

按以下维度逐项速览，每项用一句话总结现状：

| 维度 | 检查动作 | 输出 |
|------|---------|------|
| 企微基建 | Glob `_private-domain/*/ecosystem/scrm-blueprint.yaml`，存在则 Read 统计员工号数、活码数、标签维度数 | 有/无 + 关键配置数 |
| 社群健康 | Glob `_private-domain/*/community/community-playbook.md`，存在则 Read 统计社群层数和活跃率目标 | 社群层数 + 活跃率目标 |
| 生命周期 | Glob `_private-domain/*/lifecycle/lifecycle-automation.py`，存在则 Read 统计阶段数和触达规则数 | 阶段数 + 自动化规则数 |
| 转化漏斗 | Glob `_private-domain/*/funnel/funnel-strategy.md`，存在则 Read 统计渠道数和各环节转化率目标 | 渠道数 + 整体转化率目标 |

将速览结果保存到 `_private-domain/quick-scan-{当前日期}.md`，每个维度不超过 5 行。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. 使用 Glob 扫描 `_private-domain/*/meta/state.md`，列出所有任务目录
2. 对每个任务目录，Read `meta/state.md` 获取 `next_step`，然后检查四个阶段产出文件是否存在：
   - `ecosystem/scrm-blueprint.yaml` → 企微搭建已完成
   - `community/community-playbook.md` → 社群运营已完成
   - `lifecycle/lifecycle-automation.py` → 生命周期已完成
   - `funnel/funnel-strategy.md` → 转化漏斗已完成
   - 若产出文件存在但 state.md 未标记完成，以产出文件为准
3. 使用 `AskUserQuestion` 展示未完成任务及其断点位置，选项：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
转化漏斗必须有可量化 KPI。
用户生命周期必须包含触发式自动化规则。
社群运营方案必须考虑人力可执行性。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
