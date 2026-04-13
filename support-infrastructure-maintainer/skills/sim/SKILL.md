---
name: sim
description: 基础设施维护工作台——按意图路由到监控体系、IaC 框架、备份恢复或完整流程
argument-hint: "<任务描述>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash(mkdir*)", "AskUserQuestion", "Skill"]
---

# 基础设施维护工作台

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
| "监控 / 告警 / Prometheus / Grafana" | monitoring-only | 调用 `/monitoring-setup $ARGUMENTS` |
| "IaC / Terraform / 基础设施即代码" | iac-only | 调用 `/iac-framework $ARGUMENTS` |
| "备份 / 恢复 / 灾备 / DR" | backup-only | 调用 `/backup-recovery $ARGUMENTS` |
| "快速诊断 / 基础设施体检" | quick-diagnosis | → Step 3 |
| "完整方案 / 全套 或复杂需求" | full-plan | → Step 1 |

意图不明确时，用 `AskUserQuestion` 让用户选择：
- 仅监控 
- 仅IaC 
- 仅备份 
- 快速基础设施管理检查
- 完整基础设施管理流程（推荐）

**⏸️ 等待用户选择。**

---

## Step 1: 完整流程初始化

1. 从 `$ARGUMENTS` 提取任务描述，生成英文缩写（2-4 词，连字符连接）
2. 使用 `AskUserQuestion` 确认缩写
3. 创建 `_infrastructure/{当前日期}-{缩写}/` 及子目录 `context/` `meta/` 和各阶段子目录
4. 初始化 `meta/state.md`（workflow_mode、completed_steps、next_step）
5. 扫描已有目录，检查接续点（产物优先于状态文件）

**⏸️ 使用 `AskUserQuestion` 确认从哪里开始。**

---

## Step 2: 完整流程串联执行

每阶段入口重新 Read `meta/state.md`，完成后更新。

| 阶段 | 调用 | 完成标志 | 门控 |
|------|------|---------|------|
| 监控体系 | `/monitoring-setup $ARGUMENTS` | `monitoring/prometheus.yml` 存在 | 继续 / 回退 / 结束 |
| IaC 框架 | `/iac-framework $ARGUMENTS` | `iac/main.tf` 存在 | 继续 / 回退 / 结束 |
| 备份恢复 | `/backup-recovery $ARGUMENTS` | `backup/scripts/db-backup.sh` 存在 | 继续 / 回退 / 结束 |

每阶段写入摘要到 `meta/{stage}-summary.md`（不超过 20 行）。

**⏸️ 每步等待用户确认。**

---

## Step 3: 快速检查

在编排器内按以下检查表逐项执行速览，生成精简报告到 `_infrastructure/quick-scan-{日期}.md`。

| 检查维度 | 具体检查项 | 方法 |
|----------|-----------|------|
| 监控覆盖 | 关键服务是否有 Prometheus scrape 配置、告警规则是否覆盖四大黄金信号 | Glob `**/prometheus.yml` 和 `**/alert-rules.yml`，Read 检查 scrape_configs 数量和 rules 覆盖面 |
| IaC 状态 | 是否有 Terraform 配置、远程后端是否配置、资源是否包含标准标签 | Glob `**/*.tf`，Read 检查 backend 块和 tags 块是否存在 |
| 备份健康 | 备份脚本是否存在、加密是否启用、保留策略是否配置 | Glob `**/backup*.sh`，Read 检查 gpg/openssl 加密调用和 cleanup 逻辑 |
| 安全基线 | 安全组是否存在 `0.0.0.0/0` 入站、敏感信息是否硬编码 | Grep `0.0.0.0/0` 和 Grep `password\|secret\|api_key` 排查硬编码 |

每项标记 pass（已覆盖）/ warn（需改进）/ fail（缺失），汇总输出到报告文件。

使用 `AskUserQuestion`：深入某项 / 进入完整流程 / 结束。

---

## 断点恢复

1. Glob `_infrastructure/*/meta/state.md` 找到所有未完成目录
2. Read 每个 `meta/state.md`，获取 `workflow_mode`、`completed_steps`、`next_step`
3. 按如下优先级确认实际进度（产物优先于状态文件声明）：
   - 检查 `monitoring/prometheus.yml` 是否存在 → 监控阶段已完成
   - 检查 `iac/main.tf` 是否存在 → IaC 阶段已完成
   - 检查 `backup/scripts/db-backup.sh` 是否存在 → 备份阶段已完成
4. 使用 `AskUserQuestion`：从断点继续 / 重新开始

<IMPORTANT>
工作台的职责是"意图识别 + 路由 + 接续"，不是把所有请求都塞进固定管道。
监控必须覆盖 USE/RED 方法论关键指标。
备份方案必须有 RTO/RPO 目标和恢复演练计划。
IaC 方案必须考虑状态管理和 drift 检测。
每个阶段完成后必须等待用户确认。
产出文件与状态文件冲突时，以产出文件为准。
</IMPORTANT>
