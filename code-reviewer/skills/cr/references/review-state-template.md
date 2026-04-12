# 审查状态文件模板

> 路径：`meta/review-state.md` | 每阶段入口重读、每阶段完成后更新

## 基本信息

- task_name: {任务简写}
- created: {创建日期}
- workflow: {full-review|security-focus|quality-focus|refactor-focus|quick-scan|custom}
- workflow_status: {init|in-progress|completed}

## 阶段进度

| 阶段 | 状态 | 产出文件 | 完成时间 |
|------|------|---------|---------|
| 初始化 | pending/done | context/scope.md | - |
| 安全审查 | pending/in-progress/done/skipped | security/security-report-*.md | - |
| 质量审计 | pending/in-progress/done/skipped | quality/quality-report-*.md | - |
| 重构建议 | pending/in-progress/done/skipped | refactoring/refactor-report-*.md | - |

## 关键决策记录

| 时间 | 决策 | 原因 |
|------|------|------|
| - | - | - |

## 审查范围摘要

- 目标：{从 context/scope.md 摘要}
- 技术栈：{检测到的技术栈}
- 文件数：{N}

## 填充规则

1. workflow_status 跟随实际执行进度更新
2. 阶段状态与产出文件一致——产出文件存在即视为 done
3. 产出文件与状态记录冲突时，以产出文件为准
4. 断点恢复时，先检查产出文件存在性，再读状态文件
