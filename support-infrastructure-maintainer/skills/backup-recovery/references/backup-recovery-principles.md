# 备份恢复体系 — 参考原则

## 3-2-1 备份原则

- **3** 份数据副本（1 份原始 + 2 份备份）
- **2** 种不同存储介质（本地磁盘 + S3 云存储）
- **1** 份异地存储（不同数据中心/区域）
- 扩展 3-2-1-1-0：+1 份离线备份（air-gapped） + 0 个未验证备份

## 数据库备份方法速查

| 数据库 | 方法 | 命令核心 | 优缺点 |
|--------|------|----------|--------|
| MySQL 逻辑 | mysqldump | `mysqldump --single-transaction --routines --triggers --all-databases \| gzip` | 跨版本兼容，大库慢 |
| MySQL 物理 | xtrabackup | `xtrabackup --backup --target-dir=DIR` | 速度快支持增量，版本敏感 |
| PostgreSQL 逻辑 | pg_dump | `pg_dump --format=custom --compress=9 --file=FILE DB` | 支持并行恢复 |
| PostgreSQL PITR | WAL 归档 | `archive_command = 'aws s3 cp %p s3://bucket/wal/%f --sse AES256'` | 支持时间点恢复 |

## 加密方案速查

| 方案 | 加密命令 | 解密命令 | 适用场景 |
|------|---------|---------|---------|
| GPG 非对称 | `gpg --encrypt --recipient EMAIL -o FILE.gpg FILE` | `gpg --decrypt -o OUT FILE.gpg` | 密钥管理灵活（推荐） |
| AES-256 对称 | `openssl enc -aes-256-cbc -salt -pbkdf2 -in FILE -out FILE.enc -pass file:KEY` | `openssl enc -d ...` | 简单场景 |

传输安全：S3 用 `--sse AES256`，SCP/SFTP 默认 SSH，rsync 用 `-e ssh`

## S3 生命周期策略

| 阶段 | 天数 | 存储类型 | 检索延迟 |
|------|------|---------|---------|
| 近期 | 0-30 | Standard | 毫秒 |
| 中期 | 30-90 | Standard-IA | 毫秒 |
| 长期 | 90-365 | Glacier | 分钟-小时 |
| 归档 | 365-1095 | Deep Archive | 12-48 小时 |
| 过期 | >1095 | 自动删除 | - |

## RTO / RPO 参考值

| 系统级别 | RTO 目标 | RPO 目标 | 方案 |
|---------|---------|---------|------|
| 核心系统 | < 1 小时 | 0（零丢失） | 热备 + 同步复制 + WAL 归档 |
| 重要系统 | < 4 小时 | < 1 小时 | 温备 + 异步复制 + 频繁备份 |
| 一般系统 | < 24 小时 | < 24 小时 | 冷备 + 每日备份 |

计算公式：`实际 RTO = 故障检测 + 决策 + 恢复执行 + 验证`；`实际 RPO = 上次成功备份 -> 故障发生`

## 恢复测试频率

| 测试类型 | 频率 | 说明 |
|---------|------|------|
| 自动化校验 | 每次备份后 | checksum 验证、文件完整性 |
| 抽样恢复 | 每月 | 随机选取一份备份执行恢复 |
| 全量恢复演练 | 每季度 | 完整模拟灾难恢复 |
| 混沌工程测试 | 每半年 | 模拟真实故障场景 |

恢复脚本核心流程：下载备份 -> 解密（gpg --decrypt） -> 解压 -> 恢复到测试库 -> 验证行数/checksum -> 清理
