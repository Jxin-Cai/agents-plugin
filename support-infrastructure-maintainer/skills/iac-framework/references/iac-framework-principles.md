# 基础设施即代码 — 参考原则

## IaC 工具对比和选型

| 维度 | Terraform | CloudFormation | Pulumi |
|------|-----------|---------------|--------|
| 多云支持 | 优秀（AWS/GCP/Azure/阿里云） | 仅 AWS | 优秀 |
| 语言 | HCL（声明式） | YAML/JSON（声明式） | TypeScript/Python/Go |
| 社区生态 | 最活跃、模块最丰富 | AWS 官方支持 | 增长中 |
| 状态管理 | 需自行配置后端 | AWS 原生管理 | 内置托管或自建 |
| 学习曲线 | 中等 | 低（AWS 用户） | 低（开发者友好） |
| 适用场景 | 多云 / 混合云 | 纯 AWS 环境 | 需要编程逻辑 |

### 选型建议
- **纯 AWS**：CloudFormation 或 Terraform 均可
- **多云 / 混合云**：Terraform
- **团队以开发者为主**：Pulumi
- **大规模基础设施**：Terraform（生态最成熟）

## Terraform 模块化设计

### 模块分层
```
modules/
├── network/       # VPC、子网、路由、NAT
├── compute/       # EC2、ECS、Lambda、Auto Scaling
├── database/      # RDS、ElastiCache、DynamoDB
├── security/      # 安全组、IAM、KMS
├── storage/       # S3、EFS、EBS
└── monitoring/    # CloudWatch、SNS
```

### 模块接口规范
每个模块必须包含：
- `main.tf` — 资源定义
- `variables.tf` — 输入变量（带 description 和 type）
- `outputs.tf` — 输出值（供其他模块引用）

### 模块调用示例
```hcl
module "network" {
  source = "./modules/network"

  vpc_cidr           = var.vpc_cidr
  environment        = var.environment
  availability_zones = var.availability_zones
  
  tags = local.common_tags
}

module "compute" {
  source = "./modules/compute"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  instance_type      = var.instance_type
  
  tags = local.common_tags
}
```

## 状态管理

### 远程后端配置（S3 + DynamoDB）
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "env/prod/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

### 最佳实践
- 状态文件按环境隔离（不同 key 或不同 bucket）
- 启用 S3 版本控制，防止状态丢失
- 使用 DynamoDB 实现状态锁，防止并发修改
- 定期备份状态文件
- 永远不要手动编辑状态文件，使用 `terraform state` 命令

## 网络架构设计模式

### 标准三层架构
```
VPC (10.0.0.0/16)
├── 公有子网 (10.0.1.0/24, 10.0.2.0/24)
│   ├── ALB
│   ├── NAT Gateway
│   └── Bastion Host
├── 私有子网-应用层 (10.0.11.0/24, 10.0.12.0/24)
│   ├── EC2 / ECS
│   └── Lambda (VPC 内)
└── 私有子网-数据层 (10.0.21.0/24, 10.0.22.0/24)
    ├── RDS (Multi-AZ)
    └── ElastiCache
```

### CIDR 规划建议
| 子网类型 | AZ-a | AZ-c |
|---------|------|------|
| 公有 | 10.0.1.0/24 | 10.0.2.0/24 |
| 私有-应用 | 10.0.11.0/24 | 10.0.12.0/24 |
| 私有-数据 | 10.0.21.0/24 | 10.0.22.0/24 |

### 安全组设计原则
```hcl
# ALB 安全组 — 仅允许外部 HTTP/HTTPS
resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 应用安全组 — 仅允许来自 ALB 的流量
resource "aws_security_group" "app" {
  name_prefix = "${var.environment}-app-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}

# 数据库安全组 — 仅允许来自应用层的流量
resource "aws_security_group" "db" {
  name_prefix = "${var.environment}-db-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }
}
```

## Auto Scaling 策略

### 目标跟踪策略（推荐）
```hcl
resource "aws_autoscaling_policy" "cpu_target" {
  name                   = "${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}
```

### 扩缩容参数建议
| 参数 | 开发环境 | 生产环境 |
|------|---------|---------|
| min_size | 1 | 2 |
| desired_capacity | 1 | 2 |
| max_size | 2 | 10 |
| health_check_grace_period | 120s | 300s |
| default_cooldown | 120s | 300s |

## 数据库配置最佳实践

### RDS 配置模板
```hcl
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-${var.db_name}"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_encrypted     = true
  kms_key_id           = var.kms_key_arn

  multi_az               = var.environment == "prod" ? true : false
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]

  backup_retention_period = var.environment == "prod" ? 30 : 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "Mon:04:00-Mon:05:00"

  performance_insights_enabled = true
  monitoring_interval         = 60
  monitoring_role_arn         = var.rds_monitoring_role_arn

  deletion_protection = var.environment == "prod" ? true : false
  skip_final_snapshot = var.environment == "prod" ? false : true

  tags = merge(var.tags, {
    Name = "${var.environment}-${var.db_name}"
  })
}
```

### 参数组优化（MySQL 8.0）
```hcl
resource "aws_db_parameter_group" "mysql8" {
  family = "mysql8.0"
  name   = "${var.environment}-mysql8-params"

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_unicode_ci"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  parameter {
    name  = "long_query_time"
    value = "1"
  }

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }
}
```
