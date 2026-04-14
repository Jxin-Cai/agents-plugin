# 阶段摘要模板

写入路径：`.e2e-tests/tasks/{date}-{slug}/context/stage-{N}-summary.md`

## Stage 1: 任务装配与澄清

```markdown
# Stage 1 摘要

## 装配结果
task_type / workflow / trigger_source / 交付物

## 被测对象
名称 / 风险等级 / 测试目标

## 成功判据 / 不可接受结果
## 关键依赖（表格）
## 候选可复用资产
## Workflow 决策依据
## Out of Scope
```

## Stage 2: 项目上下文

```markdown
# Stage 2 摘要

## 上下文文件路径
## 关键调用链
## 异步链路与一致性窗口
## 可观察信号（UI / API / Data / Side Effect）
## 已识别可复用资产
```

## Stage 3: 测试剧本

```markdown
# Stage 3 摘要

## 剧本概览
| 剧本 | 业务场景 | case 数 | 风险 | 主要 Oracle | 复用资产 |
```

## Stage 4: 测试准备

```markdown
# Stage 4 摘要

## 准备方案
| 剧本 | 方案 | 准备度 |

## 环境配置确认
| 环境 | 配置文件 | 账号 | blocked_scripts | 状态 |

## 资产决策（复用 / 新增 / 任务专用）
## BLOCKED/PARTIAL 原因
```

## Stage 5: 测试执行

```markdown
# Stage 5 摘要

## 执行概览
| 剧本 | Case | 执行路径(A/B/C) | 结果 | 主要证据 |

## 失败归因
## 沉淀候选
```

## Stage 6: 自动化沉淀

```markdown
# Stage 6 摘要

## 沉淀结果
| 脚本 | 类型 | 覆盖场景 | 注册表状态 |

## 未沉淀原因
```
