# 标杆对照清单

> 逐条对照目标插件，不合格项必须修复。

---

## 1. 编排器是路由型还是管道型？

- **合格**：有意图识别 + workflow 路由表，至少 3 种 workflow（full / single-focus / quick-scan）
- **不合格**：固定线性管道（Step1→Step2→Step3 无分支）
- **修复**：重写为路由型（参照 SKILL.md 中 2.1 的结构模板）

## 2. 是否有状态持久化？

- **合格**：完整流程有 `meta/state.md`（含 workflow_mode、completed_steps、next_step）
- **不合格**：无状态文件，全靠对话记忆
- **修复**：在完整流程 Step 1 中添加 state.md 初始化 + 每阶段更新

## 3. 是否按需加载 references？

- **合格**：编排器入口不 Read 任何 reference，workflow 确定后才按需 Read
- **不合格**：编排器开头 `Read references/xxx.md`
- **修复**：移除入口 Read，改为 workflow 分支内按需 Read

## 4. 是否有用户确认门控？

- **合格**：每个关键阶段后 `AskUserQuestion` + ⏸️ 标记
- **不合格**：阶段间自动推进，或仅末尾一次确认
- **修复**：在每个阶段完成后添加 `AskUserQuestion`（选项：继续 / 回退 / 结束）

## 5. 是否有产物优先规则？

- **合格**：明确写有"产出文件与状态文件冲突时，以产出文件为准"
- **不合格**：无此规则
- **修复**：在断点恢复段落和 `<IMPORTANT>` 中添加

## 6. Session Hook 是否有工作区感知？

- **合格**：启动脚本输出任务计数、最近任务列表、进度状态
- **不合格**：仅 `mkdir -p` + `cat agent.md`
- **修复**：添加 `find` 统计 + `ls -1t` 列表 + state 文件读取

## 7. 子技能是否有 allowed-tools？

- **合格**：每个子技能 frontmatter 有 `allowed-tools`
- **不合格**：子技能 frontmatter 无此字段
- **修复**：根据技能类型添加（分析型: Read/Glob/Grep/AskUserQuestion，生成型: 加 Write）

## 8. References 是否充分且精简？

- **合格**：复杂子技能有 principles/template reference；每个 reference ≤100 行
- **不合格**：复杂子技能无 reference 裸奔，或 reference 超 100 行
- **修复**：缺失则补（原则用列表，模板用结构化 markdown）；过长则分片

## 9. 是否有领域专属质量硬规则？

- **合格**：`<IMPORTANT>` 中有 2-4 条该领域特有的可验证规则
- **不合格**：仅有通用规则（"等待用户确认"）或无 IMPORTANT
- **修复**：从该角色的专业标准中提炼（如审计必须引用标准条款）
