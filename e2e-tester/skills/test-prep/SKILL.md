---
name: test-prep
description: 为剧本生成测试准备方案，包含资产决策、依赖健康、readiness gate
allowed-tools: Read, Glob, Write, AskUserQuestion
---

# 测试准备器

围绕已确认剧本，生成可执行的准备方案，对资产做复用/定制/新建决策，给执行阶段提供 readiness gate。

## 流程

### Step 0: 检索共享资产与环境配置

读取当前 run 的 `task.md`、`index.md`、已有 TP 文件、`.e2e-tests/scenarios/{scenario}/scenario.md`、`.e2e-tests/shared/`、`.e2e-tests/shared/asset-catalog.md`、`.e2e-tests/shared/registry/`、`.e2e-tests/shared/quality-ledger.md`（只提取与当前 domain 相关的环境陷阱和依赖稳定性条目）。

额外检查目标环境配置：
- 读取 `target_env`
- 检查 `.e2e-tests/shared/env/{target_env}.yaml` 是否存在
- 不存在时：用 `AskUserQuestion` 收集 `base_url` / `api_base_url` / `start_urls` / 认证方式 / 账号角色 / blocked_scripts / browser profile / feature flags / preflight checks / 部署、重置、清理脚本 / stability 参数，再按 `skills/e2e/references/env-config-template.md` 落盘
- 已存在时：读取并确认账号、URL、start_urls、browser profile、blocked_scripts、preflight checks、deploy_scripts 是否仍然有效
- 密码始终用 `${ENV_VAR}` 占位，同时提醒用户在运行环境中配置对应环境变量

额外检查认证脚本：
- 检查 `.e2e-tests/shared/automation/auth/` 下是否有对应环境的认证脚本
- 有 → 记录到准备方案中作为可复用资产
- 无 → 在准备方案中标注需要在执行阶段沉淀

> 若当前 run 的 `task.md` 或 `.e2e-tests/scenarios/{scenario}/scenario.md` 不存在，提示用户先完成前置阶段，不凭空生成准备方案。

### Step 1: 从剧本提取准备项

提取 persona、preconditions、dependencies、oracle_types、reused_assets、Acceptance Source / Step Mapping → 整理：账号、数据、Mock/Fixture、依赖健康、特性开关、browser profile、启动 URL、preflight checks、部署/重置/清理脚本、隔离策略、清理策略。

### Step 2: 生成准备方案

写入 `.e2e-tests/scenarios/{scenario}/runs/{run}/prep/TP-{NNN}-{slug}.md`。

结构：关联信息、验收步骤映射引用、资产决策表（reuse/clone-and-tune/new-task/new-shared）、账号权限、环境配置引用（含 browser/start_urls/preflight_checks/deploy_scripts/stability）、认证脚本引用、前置数据、依赖策略、依赖健康探测、环境隔离策略、数据准备策略（api-create/db-seed/fixture-import/snapshot-restore）、清理策略、准备度结论（READY/PARTIAL/BLOCKED）。

已有 TP 文件时补齐而非推倒重来。

### Step 3: 共享资产沉淀

任务专用 → `.e2e-tests/scenarios/{scenario}/runs/{run}/fixtures/`；可复用 → `.e2e-tests/shared/datasets/`、`.e2e-tests/shared/mocks/`、`.e2e-tests/shared/helpers/`

**认证脚本沉淀**：若发现登录凭证且 `shared/automation/auth/` 下没有对应环境的认证脚本，建议通过 `test-automation-builder` 沉淀为 `shared/automation/auth/login-{env}.test.ts`。

### Step 4: 准备度判定

以下任一成立 → 不判 READY：核心账号未明确、关键前置数据缺失、依赖策略未明确、Mock/Fixture 缺失、副作用不可观测、清理方式不明、real 依赖健康探测未通过、共享环境无隔离机制、目标环境配置缺失、浏览器入口或 start URL 不明确、preflight 失败、导出脚本所需的登录/重置链路不可复现。

### Step 5: 更新索引并确认

更新当前 run 的 `index.md`，登记 prep 信息和 readiness 状态。`AskUserQuestion` 确认准备度。

### 落盘检查

确认以下文件已写入：
- `.e2e-tests/scenarios/{scenario}/runs/{run}/prep/TP-{NNN}-{slug}.md`（本次生成的每个方案）
- 当前 run 的 `index.md`（已更新）
- `.e2e-tests/shared/env/{target_env}.yaml`（已确认或新建）

缺失则补写。

## 约束

1. 准备方案必须落文件
2. 无 readiness 结论不进执行
3. 准备项必须服务于 oracle
4. 数据准备必须可复现
5. 共享环境必须说明隔离
6. 优先复用共享资产
7. 环境配置应优先沉淀到共享区，而不是散落在任务目录
8. 浏览器、部署脚本、preflight 和稳定性参数属于可复跑上下文，必须进入 `shared/env/{target_env}.yaml` 或准备方案

<IMPORTANT>
准备项缺失应阻止执行，而不是边跑边猜。
</IMPORTANT>
