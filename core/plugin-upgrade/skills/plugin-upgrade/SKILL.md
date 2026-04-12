---
name: plugin-upgrade
description: 插件升级工作台——从资深专业角色和 Claude Code 最佳实践两个视角迭代升级插件
argument-hint: "<目标插件目录名，如 'code-reviewer'>"
allowed-tools: ["Read", "Write", "Edit", "Glob", "Grep", "Bash(ls*|find*|wc*|head*|mkdir*)", "AskUserQuestion"]
---

# 插件升级工作台

用户传入的参数：`$ARGUMENTS`（目标插件目录名）

---

## Step 0: 定位目标与发现文件

1. 从 `$ARGUMENTS` 提取插件目录名（如 `code-reviewer`），确认 `{plugin}/` 目录存在
2. 自动发现关键元数据：

```
plugin.json  ← {plugin}/.claude-plugin/plugin.json
编排器缩写   ← skills/ 下名称最短的目录（通常 2-4 字符）
子技能列表   ← skills/ 下除编排器外的所有目录
workspace   ← hooks/session-start.sh 中 mkdir -p 的目标
agent_ref   ← hooks/session-start.sh 中 cat 的文件路径
```

3. 用 Glob 扫描所有 `{plugin}/skills/*/SKILL.md` 和 `{plugin}/skills/*/references/*.md`
4. 向用户简报发现结果（编排器名、子技能数、reference 数）

---

## Step 1: 全量阅读

按以下顺序逐一 Read（不可跳过）：

| 优先级 | 文件 | 目的 |
|--------|------|------|
| P0 | `skills/{abbr}/SKILL.md` | 理解编排架构 |
| P0 | `hooks/session-start.sh` | 理解启动行为 |
| P1 | 每个子技能 `SKILL.md` | 理解执行逻辑 |
| P1 | 所有 `references/*.md` | 理解支撑材料 |
| P2 | `.claude-plugin/plugin.json` | 确认技能注册 |
| P2 | `commands/*.md` | 确认入口别名 |

读完后在脑中形成：编排器是路由型还是管道型？子技能是否自足？references 是否按需加载？

---

## Step 2: 阶段一——资深专业角色视角升级

> **角色切换**：从此刻起，你是该插件所扮演角色的资深从业者（如 code-reviewer → 资深代码审查专家）。

Read `references/benchmark-checklist.md`（标杆对照清单）。

逐条检查当前插件，对每个不合格项执行修复：

### 2.1 编排器升级（`skills/{abbr}/SKILL.md`）

对照清单第 1-5 项。如果编排器是固定管道（A→B→C），重写为路由型：

**路由型编排器结构**：
```
frontmatter（含 allowed-tools）
↓
Step 0: 意图识别 + 路由表（意图信号 → workflow → 动作）
↓
Step 1: 完整流程初始化（仅 full workflow）
  - 工作目录创建 + meta/state.md 初始化 + 接续判断
↓
Step 2: 串联执行（阶段表 + 门控 + 摘要写入）
↓
Step 3: 快速扫描（编排器内轻量执行）
↓
断点恢复段落
↓
<IMPORTANT> 质量硬规则 </IMPORTANT>
```

**路由表设计规则**：
- 从子技能列表反推 workflow：每个子技能对应一个 `{name}-only` 路由
- 增加 `full`（串联所有子技能）和 `quick-scan`（编排器内轻量）两个额外路由
- 意图信号用该领域的自然语言关键词（中文为主）

### 2.2 Session Hook 升级（`hooks/session-start.sh`）

对照清单第 6 项。升级为三段式：
```bash
# 1. 创建工作目录
mkdir -p {workspace}
# 2. 工作区状态感知（任务计数 + 最近任务 + 进度检测）
echo "## {角色}工作台状态"
# 3. 注入角色行为原则
cat "{agent_ref}"
```

### 2.3 子技能与 References 检查

对照清单第 7-9 项：
- 子技能缺少 `allowed-tools` → 补上
- 子技能缺少 reference 且内容复杂（>80 行规则/原则）→ 拆出 reference
- reference 超过 100 行 → 分片或压缩

### 2.4 领域质量规则注入

在编排器 `<IMPORTANT>` 中添加 2-4 条**该领域特有的**质量硬规则。
规则必须具体可验证（如"合规建议必须引用具体法规条款"），不可是泛泛的"要保证质量"。

**⏸️ 阶段一完成，向用户展示改动摘要（改了哪些文件、每个文件改了什么），等待确认再进入阶段二。**

---

## Step 3: 阶段二——Claude Code 最佳实践优化

Read `references/cc-optimization-directives.md`（CC 优化指令集）。

按优先级逐条扫描所有已修改和未修改的文件，发现问题直接修复：

| 优先级 | 检查项 | 修复动作 |
|--------|--------|---------|
| P0 | 编排器无 `allowed-tools` | 补上，范围限定到实际所需 |
| P0 | 关键规则未用 `<IMPORTANT>` 包裹 | 包裹最重要的 3-5 条 |
| P0 | 步骤指令模糊（"分析一下""检查一下"） | 改为具体动作（"Read X 文件，检查 Y 是否存在"） |
| P1 | 编排器入口全量加载 references | 改为条件加载（workflow 确定后按需 Read） |
| P1 | 段落描述可压缩为表格 | 转为表格 |
| P1 | reference 超 100 行 | 分片或删减 |
| P2 | 子技能缺 `allowed-tools` | 补上 |
| P2 | 冗余文本（重复规则、过度说明） | 删除 |

**⏸️ 阶段二完成，向用户展示优化摘要。**

---

## Step 4: 验证

1. 用 Glob 确认所有 SKILL.md 中引用的 reference 路径实际存在
2. 确认 `plugin.json` 中的 skills 列表与实际 `skills/` 目录一致
3. 确认编排器路由表中的子技能调用路径（`/{skill-name}`）与实际技能名匹配
4. 检查 session-start.sh 中的 `cat` 路径指向存在的文件

如有不一致，立即修复并报告。

---

## 成功标准

| 维度 | 合格条件 |
|------|---------|
| 编排器 | 路由型（≥3 种 workflow），非管道型 |
| 状态管理 | 完整流程有 `meta/state.md` 初始化和接续逻辑 |
| 条件加载 | 编排器入口不全量 Read references |
| Session Hook | 有工作区状态感知（任务计数 + 进度） |
| allowed-tools | 编排器和所有子技能均声明 |
| IMPORTANT | 编排器有领域专属质量硬规则 |
| 引用完整性 | 所有 reference 路径可达 |

<IMPORTANT>
## 不可违反的规则

1. 不删除原有技能名，不改变 plugin.json 中的 name 字段
2. 不在编排器开头全量 Read 所有 references——这是最常见的 token 浪费
3. 阶段一修改完必须停顿等用户确认，再进入阶段二——防止用户想先 review 阶段一
4. 每个 reference 文件不超过 100 行——超过就分片
5. 路由表中的 workflow 必须能实际执行（子技能路径正确），不可写假路由
6. 升级后必须执行 Step 4 验证，不可跳过
</IMPORTANT>
