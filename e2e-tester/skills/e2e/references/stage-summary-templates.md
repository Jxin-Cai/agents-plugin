# 阶段摘要模板

写入路径：`.e2e-tests/scenarios/{scenario}/runs/{run}/context/stage-{N}-summary.md`

### Stage 1: 任务装配与澄清
必含字段：task_type / workflow / trigger_source / 交付物 / 被测对象 / 风险等级 / 测试目标 / 成功判据 / 不可接受结果 / 关键依赖（表格）/ 候选可复用资产 / Workflow 决策依据 / Out of Scope

### Stage 2: 项目上下文
必含字段：上下文文件路径（场景级）/ 关键调用链 / 异步链路与一致性窗口 / 可观察信号（UI/API/Data/SideEffect）/ 已识别可复用资产

### Stage 3: 测试剧本
必含字段：剧本概览表（`| 剧本 | 业务场景 | case数 | 风险 | 主要Oracle | 复用资产 |`）/ 剧本文件路径

### Stage 4: 测试准备
必含字段：准备方案表（`| 剧本 | 方案 | 准备度 |`）/ 环境配置确认表（`| 环境 | 配置文件 | 账号 | blocked_scripts | 认证脚本 | 状态 |`）/ 资产决策（复用/新增/任务专用）/ BLOCKED/PARTIAL 原因

### Stage 5: 测试执行
必含字段：执行概览表（`| 剧本 | Case | 执行路径(A/B/C) | 结果 | 主要证据 |`）/ 失败归因 / 沉淀候选 / 认证脚本沉淀状态

### Stage 6: 自动化沉淀
必含字段：沉淀结果表（`| 脚本 | 类型 | 覆盖场景 | 注册表状态 |`）/ 认证脚本表（`| 环境 | 脚本路径 | 状态 |`）/ 未沉淀原因
