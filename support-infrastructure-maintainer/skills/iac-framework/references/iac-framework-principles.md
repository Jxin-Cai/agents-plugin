# 基础设施即代码 — 参考原则

## IaC 工具选型

| 维度 | Terraform | CloudFormation | Pulumi |
|------|-----------|---------------|--------|
| 多云支持 | 优秀 | 仅 AWS | 优秀 |
| 语言 | HCL（声明式） | YAML/JSON | TypeScript/Python/Go |
| 社区生态 | 最活跃 | AWS 官方 | 增长中 |
| 状态管理 | 需自行配置后端 | AWS 原生 | 内置托管 |
| 适用场景 | 多云/混合云 | 纯 AWS | 需编程逻辑 |

选型建议：纯 AWS 用 CloudFormation/Terraform；多云用 Terraform；开发者为主用 Pulumi

## Terraform 模块化设计

模块分层：`network/`（VPC/子网/路由）、`compute/`（EC2/ECS/Lambda）、`database/`（RDS/ElastiCache）、`security/`（安全组/IAM/KMS）

每个模块必须包含 `main.tf`（资源定义）、`variables.tf`（输入变量 + description + type）、`outputs.tf`（供其他模块引用）

## 远程后端配置

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "env/prod/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-lock"
  }
}
```

最佳实践：按环境隔离 key/bucket、启用 S3 版本控制、DynamoDB 状态锁、定期备份、禁止手动编辑

## 网络架构：标准三层

| 子网类型 | AZ-a CIDR | AZ-c CIDR | 用途 |
|---------|-----------|-----------|------|
| 公有 | 10.0.1.0/24 | 10.0.2.0/24 | ALB、NAT Gateway、Bastion |
| 私有-应用 | 10.0.11.0/24 | 10.0.12.0/24 | EC2、ECS、Lambda |
| 私有-数据 | 10.0.21.0/24 | 10.0.22.0/24 | RDS（Multi-AZ）、ElastiCache |

## 安全组链式设计

| 安全组 | 入站来源 | 端口 | 原则 |
|--------|---------|------|------|
| ALB | 0.0.0.0/0 | 443 | 仅 HTTPS |
| 应用层 | ALB 安全组 | 8080 | 仅允许 ALB 流量 |
| 数据库 | 应用层安全组 | 3306/5432 | 仅允许应用层流量 |

## Auto Scaling 参数

| 参数 | 开发环境 | 生产环境 |
|------|---------|---------|
| min_size | 1 | 2 |
| desired_capacity | 1 | 2 |
| max_size | 2 | 10 |
| health_check_grace_period | 120s | 300s |

推荐目标跟踪策略：`ASGAverageCPUUtilization` target_value = 60.0

## RDS 配置要点

| 配置项 | 开发环境 | 生产环境 |
|--------|---------|---------|
| multi_az | false | true |
| backup_retention_period | 7 天 | 30 天 |
| deletion_protection | false | true |
| skip_final_snapshot | true | false |
| storage_encrypted | true | true |
| performance_insights | true | true |

MySQL 8.0 参数组要点：`character_set_server=utf8mb4`、`slow_query_log=1`、`long_query_time=1`、`innodb_buffer_pool_size={DBInstanceClassMemory*3/4}`
