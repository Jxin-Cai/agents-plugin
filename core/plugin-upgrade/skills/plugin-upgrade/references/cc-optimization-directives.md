# CC 优化指令集

> 按优先级排列。发现问题直接修复，无问题跳过。

---

## P0：必须修复

### 1. allowed-tools 声明
- 编排器 frontmatter 必须有 `allowed-tools`
- 编排器需要：Read, Write, Glob, Bash(mkdir*), AskUserQuestion, Skill
- 子技能按类型：分析型去掉 Write/Skill，生成型保留 Write 去掉 Skill

### 2. IMPORTANT 锚定
- 编排器末尾用 `<IMPORTANT>` 包裹最关键的 3-5 条规则
- 必须包含：不默认跑完整管道 / 每阶段等待确认 / 产物优先规则
- 必须包含 2-4 条领域专属质量规则

### 3. 步骤指令具体化
- 禁止模糊指令："分析一下""检查一下""评审一下"
- 改为："Read {路径}，检查是否包含 {具体内容}，若缺失则 {具体动作}"
- 每个 Step 的输入和输出必须明确

---

## P1：应该修复

### 4. 条件加载
- 编排器 Step 0（路由）阶段不 Read 任何 reference
- reference 在对应 workflow 分支内按需 Read
- 子技能在自己的"加载引用"步骤中 Read 自己的 reference

### 5. 表格优先
- 路由表、阶段执行表、检查清单用 markdown 表格
- 段落描述仅用于解释"为什么"，"做什么"用表格

### 6. Reference 精简
- 单个 reference ≤100 行
- 超过则拆分为多个文件，或压缩段落为列表
- 合并冗余 reference（如多个 principles 可合并为一个表格）

---

## P2：可以修复

### 7. 子技能 allowed-tools
- 为每个子技能添加 frontmatter allowed-tools
- 范围比编排器窄（无 Skill，按需有无 Write）

### 8. 冗余文本删除
- 删除"你是 xxx 的 xxx 模式——像 xxx 一样"等角色铺垫（agent.md 已注入）
- 删除重复出现的规则（抽到 reference 统一引用）
- 删除成功/失败指标中与执行步骤重复的内容
