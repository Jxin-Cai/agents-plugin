---
name: impact-analysis
description: 分析代码变更对已有测试的影响，推导需要回归的剧本和脚本。当用户提到"这次改了什么需要测"、"回归分析"、"影响分析"、"哪些测试要跑"，或提供 git commit/PR/diff 时触发。
allowed-tools: Read, Write, Glob, Grep, Skill, Bash(git log*), Bash(git diff*), Bash(git show*), AskUserQuestion
---

# 变更影响分析

从 git diff / commit / PR 出发，结合 system-map 的调用链知识和 registry 的测试覆盖元数据，推导出哪些已有测试需要回归、哪些链路缺少覆盖。

---

## 触发场景

- 用户提供 git commit SHA、PR 号、分支名或 diff 范围
- 用户说"这次改动影响哪些测试"、"需要跑哪些回归"
- 用户在开发完一个功能后，想知道测试范围

---

## 执行流程

### Step 1: 收集变更范围

**方式 A: 用户提供 commit / branch / PR**

```bash
# 单 commit
git diff {commit}^ {commit} --name-only

# 分支 vs main
git diff main...HEAD --name-only

# 查看改动详情
git diff main...HEAD --stat
```

**方式 B: 用户描述功能**

从描述中提取关键词，用 Grep 搜索相关源码文件。

输出：变更文件路径列表 + 变更摘要（新增/修改/删除了什么）。

### Step 2: 加载系统知识

读取以下文件：
- `.e2e-tests/system-map.md` — 源码路径 → 服务/调用链映射
- `.e2e-tests/registry/index.yaml` — 已有测试覆盖
- `.e2e-tests/asset-catalog.md` — 跨 domain 资产
- `.e2e-tests/quality-ledger.md` — 历史失败模式和环境陷阱

如果 `system-map.md` 不存在或变更文件未在映射中，需要临时扫描变更文件确定涉及的服务和 API 端点。

### Step 3: 影响推导

按以下顺序逐层推导：

**层 1: 直接命中**
- 变更文件路径匹配 system-map 的"源码路径 → 服务/功能映射"
- 变更文件路径匹配 registry 中脚本的 `source_paths`

**层 2: 服务级扩散**
- 变更涉及的服务 → system-map 中该服务参与的所有调用链 → 调用链涉及的其他服务
- 重点关注：变更服务的**下游服务**是否有依赖此接口的测试

**层 3: API 端点级匹配**
- 变更文件中定义/修改的 API 端点 → registry 中 `api_endpoints` 包含这些端点的脚本

**层 4: 风险级补充**
- quality-ledger 中与变更服务相关的失败模式是否为 `active`
- 变更涉及的模块是否属于高风险区域（High risk 的剧本覆盖的模块）

### Step 4: 生成影响报告

用 `AskUserQuestion` 向用户展示分析结果，结构如下：

```
## 变更摘要
- 变更文件: {N} 个
- 涉及服务: {services}
- 涉及调用链: {chains}

## 需要回归的已有测试
| 优先级 | 剧本/脚本 | domain | 命中原因 | 上次结果 | 脚本路径 |
|--------|----------|--------|---------|---------|---------|

优先级规则:
- P0: 变更直接命中脚本 source_paths 或 api_endpoints
- P1: 变更服务在调用链上，下游脚本可能受影响
- P2: 同 domain 的其他剧本，风险等级 High
- P3: quality-ledger 中有 active 失败模式涉及此服务

## 缺少覆盖的风险
- {变更涉及的功能/端点，但 registry 中无对应测试}

## 建议动作
- [ ] 直接回归: 执行以上 P0/P1 脚本
- [ ] 补充测试: 为缺少覆盖的部分新建任务
- [ ] 探索验证: 对不确定影响的调用链做路径 C 探索
```

使用 `AskUserQuestion` 让用户选择后续动作（`multiSelect: true`）：
- 批量执行 P0/P1 回归脚本
- 选择性执行部分脚本
- 为缺失覆盖创建新的 E2E 测试任务
- 仅查看报告，不执行

### Step 5: 按用户选择执行

- **批量回归**：逐个执行选中的脚本，汇总结果
- **新建任务**：调用 `/e2e` 进入完整流程，将影响分析结果作为澄清阶段的输入
- **仅报告**：将影响报告写入 `.e2e-tests/reports/impact-{date}-{slug}.md`

---

## 约束

1. **有 system-map 才做推导，没有就建**——如果 system-map 为空或变更路径不在映射中，先提示用户：需要先通过 scan-context 建立映射，或手动确认变更涉及的服务
2. **不猜测，标注置信度**——推导链超过 2 层时标注"间接影响，建议人工确认"
3. **优先级明确**——不要把所有测试都列为 P0，真正直接命中的才是 P0
4. **不自动执行**——分析结果展示后必须等用户确认才执行回归
5. **分析结果落文件**——影响报告写入 reports，供追溯
