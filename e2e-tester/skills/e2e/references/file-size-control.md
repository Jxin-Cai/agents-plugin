# 状态文件膨胀控制规范

各状态文件的容量限制与分片策略。skill 在写入前检查行数，触及阈值时执行分片。

## 阈值与策略

| 文件 | 软阈值 | 硬阈值 | 分片策略 |
|------|--------|--------|---------|
| `scenario.md` | 150 行 | 200 行 | 超过时按 case 分组，每 case 移到 `scenario-cases/{case-id}.md`，主文件保留 frontmatter + case 索引表 |
| `index.md` | 100 行 | 150 行 | 超过时收折历史区块：Decision Log 保留最近 5 条，Stage 产物只保留路径引用，修正记录保留最近 10 条 |
| `quality-ledger.md` | 300 行 | 400 行 | 按 `quality-ledger-template.md` 的分片规则：按业务域分片到 `shared/quality-ledger/{domain}.md` |
| `knowledge-index.md` | 150 行 | 200 行 | 每表最多 20 行，超出时按优先级截断（脚本按 confidence DESC，陷阱按 active 优先） |
| `asset-catalog.md` | 200 行 | 250 行 | 按区块分片：顶层每区块保留前 10 条 + 总数，完整内容移到 `shared/{category}/README.md` |
| `context-*.md` | 200 行 | 300 行 | 按维度拆分：每维度独立文件 `context/{slug}-{dimension}.md`，主文件保留索引 |

## scenario.md 分片详情

触及 150 行时：
1. `mkdir -p .e2e-tests/scenarios/{scenario}/scenario-cases/`
2. 每个 case 块（从 `### Case:` 到下一个 `### Case:` 或文件末尾）移到 `scenario-cases/{case-id}.md`
3. 主文件替换为：
   ```markdown
   ## Cases（索引）
   | Case ID | 名称 | 风险 | Oracle 类型 | 文件 |
   |---------|------|------|-----------|------|
   | TC-001 | ... | High | API+UI | scenario-cases/tc-001.md |
   ```
4. 读取 case 详情时按需从子文件加载

## index.md 收折详情

触及 100 行时：
1. **Decision Log**：保留最近 5 条，旧记录移到同目录 `decision-log-archive.md`
2. **Stage 产物区**：已完成 stage 只保留一行状态 + 产物路径，不展开详情
3. **修正记录**：保留最近 10 条，旧记录移到同目录 `fix-history-archive.md`
4. **Acceptance Source**：step 数 ≤ 10 保留原文，> 10 只保留 step_count + 文件引用

## 执行时机

- **写入前检查**：skill 在写入状态文件前用 `wc -l` 检查行数
- **软阈值**：日志记录警告，下次写入时分片
- **硬阈值**：立即分片后再写入
- **分片后验证**：确认主文件行数回落到软阈值以下
