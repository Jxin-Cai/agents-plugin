# Quality Ledger 模板

`.e2e-tests/quality-ledger.md` — 跨任务质量经验缓存。存在时加速，缺失不阻塞。

```markdown
# Quality Ledger

## 失败模式库
### FM-{NNN}: {名称}
- 现象 / 根因 / 涉及服务 / 推荐处理
- 首次发现 / 复现次数 / 最后出现 / 状态: active | resolved

## 时序基线
| 链路 | 操作 | P50 | P90 | 最大观测值 | 最后验证 |

## 环境陷阱
### ET-{NNN}: {名称}
- 环境 / 现象 / 规避 / 状态: active | resolved

## 依赖稳定性画像
| 服务 | 历史可用率 | 常见故障 | 推荐策略 | 降级方案 |

## Flaky 治理
| 剧本 | Case | 根因 | 治理方式 | 状态 |

## 变更日志
| 日期 | 操作 | 区块 | 来源任务 |
```

## 规则

- test-runner 回写：失败归因、flaky、时序、环境问题
- 去重：同现象/服务/根因时更新复现次数，不重复添加
- test-prep 读取：环境陷阱 + 依赖稳定性
- test-runner 读取：时序基线 + 失败模式

## 分片

超 300 行时：顶层保留摘要 + 最近 5 条 active，详细条目按 domain 分片到 `.e2e-tests/{domain}/quality-ledger.md`。
清理：resolved 超 180 天的失败模式/环境陷阱、超 90 天的 flaky、变更日志保留最近 50 条。
