---
name: ticket-resolution
description: 工单处理——全渠道支持框架设计、SLA 配置、分层路由和标准处理流程
argument-hint: "<工单处理需求描述>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*)", "AskUserQuestion"]
---

# 工单处理框架设计

设计全渠道客户支持框架，包括渠道配置、SLA 策略、分层路由规则和标准处理流程，让工单从接收到关闭的每一步都有章可循。

---

加载引用资料：

```
@references/ticket-resolution-principles.md
```

---

## 强制执行规则

1. **渠道选择必须匹配业务场景**——不是渠道越多越好，是覆盖用户习惯最重要
2. **SLA 必须考虑团队实际能力**——设定不可达的目标只会打击士气
3. **路由规则必须清晰无歧义**——一条工单只能有一条明确的路径
4. **所有配置输出 YAML 格式**——可直接用于工单系统配置
5. **所有交互使用中文**

---

## 前置条件

- Read `context/business-context.md`（必须存在），提取产品类型、用户触达渠道、支持团队规模和技能分布
- Glob `tickets/` 检查是否有历史产出，有则 Read 获取上下文

---

## Step 1: 全渠道支持框架设计

Read `context/business-context.md` 提取用户常用联系渠道和团队规模。根据以下矩阵评估每个渠道的适用性，输出启用/不启用决策及理由：

### 渠道评估矩阵

| 渠道 | 适用场景 | 优先级 | 是否启用 |
|------|----------|--------|----------|
| 邮件 | 非紧急、需要详细描述的问题 | 中 | 按需 |
| 在线聊天 | 实时问题、快速咨询 | 高 | 推荐 |
| 电话 | 紧急问题、复杂沟通 | 高 | 按需 |
| 社交媒体 | 公开反馈、品牌相关 | 中 | 按需 |
| 应用内消息 | 产品内嵌支持、上下文丰富 | 高 | 推荐 |

为每个启用的渠道定义：
- 工作时间和覆盖范围
- 自动回复策略
- 人工接入触发条件
- 渠道间流转规则

输出文件：`tickets/channel-framework.yaml`

<AskUserQuestion>
请确认您想启用哪些支持渠道？当前用户主要通过什么方式联系您？
（如不确定，我会根据您的产品类型推荐最佳组合）
</AskUserQuestion>

---

## Step 2: SLA 配置

Read `tickets/channel-framework.yaml`（Step 1 产出）获取已启用渠道列表。根据团队规模校准以下默认 SLA 值，Write 输出到 `tickets/sla-config.yaml`：

```yaml
sla_policies:
  critical:  # P0 — 服务不可用
    first_response: 15m
    resolution: 4h
    escalation_after: 30m
    notification: [on-call, manager]
  high:      # P1 — 核心功能受损
    first_response: 1h
    resolution: 8h
    escalation_after: 2h
    notification: [team-lead]
  medium:    # P2 — 功能异常但有 workaround
    first_response: 4h
    resolution: 24h
    escalation_after: 8h
    notification: [assignee]
  low:       # P3 — 建议/咨询
    first_response: 8h
    resolution: 72h
    escalation_after: 24h
    notification: [assignee]
```

根据团队能力校准以上默认值，输出文件：`tickets/sla-config.yaml`

---

## Step 3: 分层路由规则

Read `tickets/sla-config.yaml`（Step 2 产出）获取优先级定义。为 T1/T2/T3 三层设计路由规则，每层明确处理范围、技能要求、工具权限和升级条件；Write 输出到 `tickets/routing-rules.yaml`：

### T1 基础支持（一线客服）
- **处理范围**：FAQ 类问题、账号操作、基础设置指导
- **技能要求**：产品功能熟悉、沟通能力
- **工具权限**：客服面板、知识库查询
- **升级条件**：
  - 超出知识库覆盖范围
  - 需要后台系统操作权限
  - 客户明确要求升级
  - 处理时间超过 SLA 50%

### T2 技术支持（二线技术）
- **处理范围**：技术故障排查、系统配置、数据修复
- **技能要求**：技术背景、系统操作能力
- **工具权限**：管理后台、日志查询、基础数据库操作
- **升级条件**：
  - 需要代码修改
  - 安全事件
  - 需要跨团队协作

### T3 专家支持（研发/安全）
- **处理范围**：Bug 修复、安全响应、架构级问题
- **技能要求**：开发能力、安全知识
- **工具权限**：代码仓库、部署系统、全权限

输出文件：`tickets/routing-rules.yaml`

---

## Step 4: 工单处理标准流程

Read `tickets/routing-rules.yaml`（Step 3 产出）获取分层定义。按工单生命周期 8 个环节（接收→分类→优先级判定→路由分配→诊断→解决→验证→关闭）逐一定义标准操作，Write 输出到 `tickets/ticket-lifecycle.yaml`：

```
接收 → 分类 → 优先级判定 → 路由分配 → 诊断 → 解决 → 验证 → 关闭
  │                                        │       │
  └─ 自动回复确认                          └─ 升级  └─ 客户确认
```

每个环节的标准操作：

1. **接收**：自动确认收到 + 预估响应时间
2. **分类**：按问题类型自动打标签（关键词匹配 + 人工复核）
3. **优先级判定**：影响面 × 紧急度矩阵
4. **路由分配**：按分层规则自动分配 + 负载均衡
5. **诊断**：标准排查 checklist + 信息补充请求模板
6. **解决**：方案执行 + 操作记录
7. **验证**：向客户确认问题已解决
8. **关闭**：满意度调查 + 知识库更新检查

输出文件：`tickets/ticket-lifecycle.yaml`

---

## Step 5: 升级和协作机制

Read `tickets/routing-rules.yaml` 和 `tickets/sla-config.yaml` 获取分层 + SLA 信息。为以下 5 项逐一制定规则，Write 输出到 `tickets/escalation-playbook.yaml`：

- 升级触发条件和通知链
- 协作工单的责任归属
- 升级后的 SLA 重新计算规则
- 管理层介入的条件和流程
- 危机管理预案（批量故障、安全事件）

输出文件：`tickets/escalation-playbook.yaml`

---

## 最终输出

`tickets/` 目录下应包含：
- `channel-framework.yaml` — 渠道支持框架
- `sla-config.yaml` — SLA 配置
- `routing-rules.yaml` — 分层路由规则
- `ticket-lifecycle.yaml` — 工单生命周期流程
- `escalation-playbook.yaml` — 升级和协作机制

---

## 成功指标

- [ ] 所有 YAML 配置语法正确、可直接导入工单系统
- [ ] 渠道选择覆盖 80%+ 用户常用联系方式
- [ ] 路由规则无歧义，每条工单有且仅有一条路径

## 失败指标

- SLA 设定未经团队能力校准
- 路由规则存在死循环或无匹配分支
- 缺少升级机制导致困难工单无人处理

---

**IMPORTANT**: 工单系统是支持体系的骨架。设计时要在"理想化"和"可执行"之间找到平衡——先跑起来，再迭代优化。每一步都要考虑：当团队只有 2 个人时，这个流程还能不能跑？
