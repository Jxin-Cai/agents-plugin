---
name: iac-framework
description: 基础设施即代码 — Terraform / CloudFormation 配置设计与输出
argument-hint: "<基础设施需求描述>"
---

# 基础设施即代码

为目标系统设计完整的 IaC 配置，涵盖网络架构、计算资源、数据库基础设施，输出可直接部署的 Terraform 或 CloudFormation 配置。

## 加载引用

Read file: `./references/iac-framework-principles.md`

## 强制执行规则

- 所有交互使用中文
- 输出的 HCL / YAML 配置必须语法正确，可直接 `terraform plan` 或 `aws cloudformation validate`
- 严禁在配置文件中硬编码密钥、密码等敏感信息
- 所有资源必须包含标签（Name、Environment、Owner、CostCenter）
- 网络设计必须遵循最小权限原则（安全组仅开放必要端口）

## 前置条件

- 已明确目标云平台（AWS / GCP / Azure）
- 已明确环境类型（生产 / 预发布 / 开发）
- 已明确服务架构（单体 / 微服务、有状态 / 无状态）
- 已明确预算范围

如信息不完整，使用 `AskUserQuestion` 补充。

## Step 1: 选择 IaC 工具

1. 根据团队技术栈和云平台选择工具：
   - **Terraform** — 多云支持、社区生态最丰富
   - **CloudFormation** — AWS 原生、与 AWS 服务深度集成
   - **Pulumi** — 使用通用编程语言（TypeScript/Python）
2. 确定状态管理方案：
   - Terraform：S3 + DynamoDB 远程后端
   - CloudFormation：AWS 原生管理
3. 确定模块化策略：
   - 网络模块（VPC、子网、路由）
   - 计算模块（EC2、ECS、Lambda）
   - 数据库模块（RDS、ElastiCache）
   - 安全模块（安全组、IAM）

使用 `AskUserQuestion` 确认工具选型。

## Step 2: 设计网络架构

1. VPC 设计：
   - CIDR 规划（如 `10.0.0.0/16`）
   - 可用区分布（至少 2 个 AZ）
2. 子网设计：
   - 公有子网（ALB、NAT Gateway）
   - 私有子网-应用层（EC2、ECS）
   - 私有子网-数据层（RDS、ElastiCache）
3. 路由和网关：
   - Internet Gateway（公有子网出口）
   - NAT Gateway（私有子网出口）
   - 路由表关联
4. 安全组设计：
   - ALB 安全组（入站 80/443）
   - 应用安全组（入站仅允许 ALB）
   - 数据库安全组（入站仅允许应用层）
5. 输出网络模块配置文件

使用 `AskUserQuestion` 确认网络架构设计。

## Step 3: 设计计算资源

1. 启动模板（Launch Template）：
   - AMI 选择
   - 实例类型（根据工作负载选择）
   - 用户数据脚本（初始化配置）
   - IAM 实例配置文件
2. Auto Scaling 组：
   - 最小/期望/最大实例数
   - 扩缩策略（目标跟踪 / 步进调整）
   - 健康检查（EC2 / ELB）
   - 终止策略
3. 负载均衡器：
   - ALB 配置（监听器、目标组）
   - 健康检查路径和阈值
   - SSL/TLS 证书
4. 输出计算模块配置文件

## Step 4: 设计数据库基础设施

1. RDS 配置：
   - 引擎和版本选择
   - 实例类型和存储
   - Multi-AZ 部署
   - 参数组优化
   - 自动备份（保留天数、备份窗口）
2. ElastiCache 配置（如需要）：
   - 引擎（Redis / Memcached）
   - 节点类型和副本数
   - 集群模式
3. 安全配置：
   - 加密存储（KMS）
   - 加密传输（SSL）
   - IAM 认证
4. 监控集成：
   - 性能洞察（Performance Insights）
   - CloudWatch 指标
   - 慢查询日志
5. 输出数据库模块配置文件

使用 `AskUserQuestion` 确认数据库配置。

## Step 5: 输出 IaC 配置

将所有配置文件整理输出至 `iac/` 目录：

```
iac/
├── main.tf                    # 主入口，模块调用
├── variables.tf               # 输入变量定义
├── outputs.tf                 # 输出值定义
├── terraform.tfvars.example   # 变量示例文件
├── backend.tf                 # 远程状态后端配置
├── modules/
│   ├── network/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── database/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

## 成功指标

- [ ] `terraform validate` 通过
- [ ] 网络架构满足高可用要求（多 AZ）
- [ ] 安全组遵循最小权限原则
- [ ] 所有资源包含标准标签
- [ ] 敏感信息通过变量或密钥管理服务引用
- [ ] 环境配置文件分离（dev / staging / prod）

## 失败指标

- 配置文件存在语法错误
- 安全组存在 0.0.0.0/0 的不必要入站规则
- 数据库缺少 Multi-AZ 配置（生产环境）
- 硬编码密钥或敏感信息
- 缺少状态后端配置

## IMPORTANT

- 生产环境数据库必须配置 Multi-AZ
- 所有存储必须启用加密（EBS、RDS、S3）
- NAT Gateway 建议在每个 AZ 各部署一个（避免跨 AZ 流量和单点故障）
- Auto Scaling 的最小实例数生产环境建议 ≥ 2
- Terraform 状态文件必须存储在远程后端，且启用版本控制和加密
