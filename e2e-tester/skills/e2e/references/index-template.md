# 任务索引模板

`task/index.md` 是单次 E2E 测试任务的**唯一状态管理文件**。断点恢复、阶段判断、产物追踪、跨阶段修正全部依赖此文件。

---

## Frontmatter 字段

```yaml
---
domain: {domain}
status: active | completed | archived
created: {YYYY-MM-DD}
last_updated: {YYYY-MM-DDTHH:mm:ss}
current_stage: {1-6 | done}
completed_stages: [1, 2, ...]
---
```

**status 说明**：

| 值 | 含义 | 触发条件 |
|----|------|----------|
| `active` | 正在进行 | 初始化时设置 |
| `completed` | 所有阶段完成 | Stage 6 完成或用户标记完成 |
| `archived` | 已归档，不再活跃 | 完成后 90 天无活动，或用户手动归档 |

---

## 正文结构

```markdown
# {domain} 测试任务索引

## 任务文件
- task/task.md — {一句话简述}

## 阶段产物

### Stage 1: 澄清
- task/task.md — {完成 / 待补充}

### Stage 2: 扫描
- context/context-{slug}.md — {完成 / 待补充}

### Stage 3: 剧本
| 文件 | 业务场景 | case 数 | 复用资产 |
|------|----------|---------|---------|

### Stage 4: 准备
| 文件 | 对应剧本 | 准备度 |
|------|----------|--------|

### Stage 5: 执行
| 报告 | 路径 | 结论 | 日期 |
|------|------|------|------|

### Stage 6: 沉淀
| 脚本 | 覆盖场景 | 置信度 |
|------|----------|--------|

## 候选可复用资产
- {从共享目录和 asset-catalog.md 匹配到的资产}

## 已沉淀资产
- {本任务沉淀到 _shared/ 或 registry 的资产}

## 后续修正记录
| 日期 | 修正阶段 | 修正内容 |
|------|----------|----------|
```

---

## 使用规则

1. **每个阶段结束时必须更新** index.md 的 frontmatter（`current_stage`、`completed_stages`、`last_updated`）和对应的阶段产物区块
2. **断点恢复时先读 frontmatter**，再与实际文件产物交叉验证；冲突时以实际文件为准
3. **后续阶段发现前置遗漏时**，在"后续修正记录"中追加条目，说明修正了哪个阶段的什么认知
4. **归档策略**：`completed` 状态超过 90 天无活动 → 建议改为 `archived`；`archived` 任务在 Step 0 会被识别并提示用户
