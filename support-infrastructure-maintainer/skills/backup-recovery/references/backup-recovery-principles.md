# 备份恢复体系 — 参考原则

## 3-2-1 备份原则

- **3** 份数据副本（1 份原始数据 + 2 份备份）
- **2** 种不同的存储介质（如本地磁盘 + S3 云存储）
- **1** 份异地存储（不同数据中心或区域）

### 扩展：3-2-1-1-0 原则
- **1** 份离线备份（air-gapped，防勒索软件）
- **0** 个未验证的备份（所有备份必须通过恢复测试验证）

## 数据库备份方法

### MySQL

#### 逻辑备份（mysqldump）
```bash
# 全库备份
mysqldump \
  --host="${DB_HOST}" \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --set-gtid-purged=OFF \
  --all-databases \
  | gzip > "${BACKUP_DIR}/mysql-full-$(date +%Y%m%d-%H%M%S).sql.gz"

# 单库备份
mysqldump \
  --host="${DB_HOST}" \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  --single-transaction \
  "${DB_NAME}" \
  | gzip > "${BACKUP_DIR}/${DB_NAME}-$(date +%Y%m%d-%H%M%S).sql.gz"
```

**优点**：跨版本兼容、可读性好、支持单表恢复
**缺点**：大库速度慢、恢复时间长

#### 物理备份（xtrabackup）
```bash
# 全量备份
xtrabackup \
  --backup \
  --host="${DB_HOST}" \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  --target-dir="${BACKUP_DIR}/full-$(date +%Y%m%d)"

# 增量备份（基于上次全量）
xtrabackup \
  --backup \
  --host="${DB_HOST}" \
  --user="${DB_USER}" \
  --password="${DB_PASS}" \
  --target-dir="${BACKUP_DIR}/incr-$(date +%Y%m%d-%H%M%S)" \
  --incremental-basedir="${BACKUP_DIR}/full-$(date +%Y%m%d)"
```

**优点**：速度快、支持增量、恢复效率高
**缺点**：版本敏感、不支持跨引擎

### PostgreSQL

#### pg_dump 逻辑备份
```bash
# 自定义格式（推荐，支持并行恢复）
pg_dump \
  --host="${DB_HOST}" \
  --username="${DB_USER}" \
  --format=custom \
  --compress=9 \
  --file="${BACKUP_DIR}/${DB_NAME}-$(date +%Y%m%d-%H%M%S).dump" \
  "${DB_NAME}"

# 恢复
pg_restore \
  --host="${DB_HOST}" \
  --username="${DB_USER}" \
  --dbname="${DB_NAME}" \
  --jobs=4 \
  "${BACKUP_FILE}"
```

#### WAL 归档（持续归档 + PITR）
```bash
# postgresql.conf
archive_mode = on
archive_command = 'aws s3 cp %p s3://backup-bucket/wal/%f --sse AES256'

# 时间点恢复
restore_command = 'aws s3 cp s3://backup-bucket/wal/%f %p'
recovery_target_time = '2026-04-07 10:30:00'
```

## 加密和传输安全

### GPG 加密
```bash
# 生成密钥对
gpg --full-generate-key

# 加密备份
gpg --encrypt \
  --recipient "backup@company.com" \
  --output "${BACKUP_FILE}.gpg" \
  "${BACKUP_FILE}"

# 解密恢复
gpg --decrypt \
  --output "${RESTORE_FILE}" \
  "${BACKUP_FILE}.gpg"
```

### OpenSSL AES-256 加密
```bash
# 加密
openssl enc -aes-256-cbc -salt -pbkdf2 \
  -in "${BACKUP_FILE}" \
  -out "${BACKUP_FILE}.enc" \
  -pass file:/path/to/keyfile

# 解密
openssl enc -aes-256-cbc -d -pbkdf2 \
  -in "${BACKUP_FILE}.enc" \
  -out "${RESTORE_FILE}" \
  -pass file:/path/to/keyfile
```

### 传输安全
- S3 传输：使用 `--sse AES256` 或 `--sse aws:kms` 服务端加密
- SCP/SFTP：默认 SSH 加密通道
- rsync：使用 `rsync -e ssh` 加密传输

## S3 生命周期策略

```json
{
  "Rules": [
    {
      "ID": "BackupLifecycle",
      "Status": "Enabled",
      "Filter": {
        "Prefix": "backups/"
      },
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        },
        {
          "Days": 365,
          "StorageClass": "DEEP_ARCHIVE"
        }
      ],
      "Expiration": {
        "Days": 1095
      }
    }
  ]
}
```

### 存储类型成本对比（大致参考）
| 存储类型 | 存储成本 | 检索延迟 | 适用场景 |
|---------|---------|---------|---------|
| S3 Standard | 高 | 毫秒 | 近期备份（< 30 天） |
| S3 Standard-IA | 中 | 毫秒 | 月度备份（30-90 天） |
| S3 Glacier | 低 | 分钟-小时 | 季度备份（90-365 天） |
| S3 Deep Archive | 极低 | 12-48 小时 | 年度归档（> 365 天） |

## 恢复测试方法论

### 测试频率
| 测试类型 | 频率 | 说明 |
|---------|------|------|
| 自动化校验 | 每次备份后 | checksum 验证、文件完整性 |
| 抽样恢复 | 每月 | 随机选取一份备份执行恢复 |
| 全量恢复演练 | 每季度 | 完整模拟灾难恢复 |
| 混沌工程测试 | 每半年 | 模拟真实故障场景 |

### 恢复测试脚本模板
```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/log/recovery-test-$(date +%Y%m%d).log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 1. 下载备份
log "下载备份文件..."
aws s3 cp "s3://backup-bucket/latest.sql.gz.gpg" /tmp/recovery-test/

# 2. 解密
log "解密备份文件..."
gpg --decrypt --output /tmp/recovery-test/latest.sql.gz /tmp/recovery-test/latest.sql.gz.gpg

# 3. 解压
log "解压备份文件..."
gunzip /tmp/recovery-test/latest.sql.gz

# 4. 恢复到测试数据库
log "恢复到测试数据库..."
mysql --host="${TEST_DB_HOST}" --user="${TEST_DB_USER}" --password="${TEST_DB_PASS}" < /tmp/recovery-test/latest.sql

# 5. 验证
log "验证数据完整性..."
ROW_COUNT=$(mysql --host="${TEST_DB_HOST}" --user="${TEST_DB_USER}" --password="${TEST_DB_PASS}" \
  -N -e "SELECT COUNT(*) FROM ${DB_NAME}.${TABLE_NAME}")
log "行数验证: ${ROW_COUNT}"

# 6. 清理
log "清理测试数据..."
rm -rf /tmp/recovery-test/

log "恢复测试完成"
```

## RTO / RPO 定义和计算

### RTO（Recovery Time Objective）— 恢复时间目标
从故障发生到系统恢复服务的最大可接受时间。

**影响因素**：
- 备份存储位置（本地 < S3 < Glacier）
- 数据量大小
- 恢复方式（物理恢复 < 逻辑恢复）
- 基础设施重建时间（IaC 自动化 < 手动操作）

**参考值**：
| 系统级别 | RTO 目标 | 方案 |
|---------|---------|------|
| 核心系统 | < 1 小时 | 热备 + 自动切换 |
| 重要系统 | < 4 小时 | 温备 + 脚本恢复 |
| 一般系统 | < 24 小时 | 冷备 + 手动恢复 |

### RPO（Recovery Point Objective）— 恢复点目标
系统可接受的最大数据丢失量（以时间衡量）。

**影响因素**：
- 备份频率（每日 / 每小时 / 实时）
- WAL/Binlog 归档频率
- 复制延迟

**参考值**：
| 数据类型 | RPO 目标 | 方案 |
|---------|---------|------|
| 交易数据 | 0（零丢失） | 同步复制 + WAL 归档 |
| 业务数据 | < 1 小时 | 异步复制 + 频繁备份 |
| 日志数据 | < 24 小时 | 每日备份 |

### RTO / RPO 计算公式
```
实际 RTO = 故障检测时间 + 决策时间 + 恢复执行时间 + 验证时间
实际 RPO = 上次成功备份时间点 → 故障发生时间点
```

**优化建议**：
- 缩短 RTO：使用 IaC 自动重建、热备 / 温备架构、自动化恢复脚本
- 缩短 RPO：提高备份频率、启用 WAL/Binlog 持续归档、使用数据库复制
