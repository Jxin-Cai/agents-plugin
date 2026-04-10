---
name: sim
description: 基础设施维护全流程编排 — 从监控体系到 IaC 到备份恢复
argument-hint: "<基础设施或系统描述>"
---

# 基础设施维护全流程编排

端到端的基础设施维护流程：监控体系搭建 → 基础设施即代码 → 备份恢复体系，确保系统高可用、可追溯、可恢复。

## 加载引用

Read file: `./references/infrastructure-maintainer-agent.md`

## 强制执行规则

- 所有交互使用中文
- 每个步骤完成后必须使用 `AskUserQuestion` 工具确认后再进入下一步
- 所有配置文件必须可直接使用，不允许占位符（除明确标注需用户填入的值）
- 工作目录严格遵循 `_infrastructure/{YYYY-MM-DD}-{任务简写}/` 结构
- 先监控、后变更、再备份，顺序不可颠倒

## 前置条件

开始前需确认以下信息（如未知则通过 `AskUserQuestion` 询问）：

- 目标系统/服务名称
- 当前技术栈（语言、框架、数据库、云平台）
- 当前部署方式（容器/虚拟机/裸机）
- 已有的监控和备份方案（如有）
- 主要痛点和优先级

## Step 0: 初始化

1. 创建工作目录 `_infrastructure/{YYYY-MM-DD}-{任务简写}/`
2. 在 `context/` 下记录：
   - `architecture.md` — 当前系统架构概览
   - `tech-stack.md` — 技术栈清单
   - `pain-points.md` — 当前痛点和改进目标
3. 使用 `AskUserQuestion` 确认上下文信息是否准确

## Step 1: 监控体系搭建

调用技能 `/monitoring-setup`，完成：
- 关键服务和指标识别
- Prometheus 监控配置
- 告警规则设计
- Grafana 仪表盘设计

产出物存放至 `monitoring/` 目录。

使用 `AskUserQuestion` 确认监控方案是否满足需求，是否进入下一步。

## Step 2: 基础设施即代码

调用技能 `/iac-framework`，完成：
- IaC 工具选型
- 网络架构设计
- 计算资源配置
- 数据库基础设施

产出物存放至 `iac/` 目录。

使用 `AskUserQuestion` 确认 IaC 配置是否满足需求，是否进入下一步。

## Step 3: 备份恢复体系

调用技能 `/backup-recovery`，完成：
- 备份策略设计
- 加密和存储方案
- 自动化调度
- 恢复流程和测试

产出物存放至 `backup/` 目录。

使用 `AskUserQuestion` 确认备份恢复方案是否完整。

## 成功指标

- [ ] 监控覆盖所有关键服务，告警规则覆盖四大黄金信号
- [ ] IaC 配置可直接 `terraform apply` 或 `aws cloudformation deploy`
- [ ] 备份脚本可直接通过 cron 调度运行
- [ ] 恢复手册包含完整步骤和预期时间（RTO）
- [ ] 所有配置文件通过语法检查

## 失败指标

- 监控存在盲区（关键服务未覆盖）
- IaC 配置存在硬编码密钥或敏感信息
- 备份方案没有加密或跨区域存储
- 恢复流程未经测试验证

## IMPORTANT

- 安全敏感信息（密钥、密码）必须使用变量引用或密钥管理服务，严禁硬编码
- 所有资源必须包含标签（Name、Environment、Owner、CostCenter）
- 告警必须配置通知渠道（邮件、Slack、PagerDuty 等），不能只写规则不通知
- 备份必须加密，且至少一份存储在异地/异区域
