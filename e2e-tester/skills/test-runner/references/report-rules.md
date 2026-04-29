# 测试质量报告规则与骨架

> 生成报告前先加载本文件了解结构和规则。完整模板见 report-template.md。

## 章节目录

1. **执行结论** — 总体verdict / 路径(A/B/C) / 风险 / 证据级别
2. **执行配置** — execution_mode / parallel_safe / workers / retry / trace / abstraction_mode / evidence_root / export_status
3. **准备度结论** — 账号 / 前置数据 / Mock / 依赖健康 / 清理策略 / 总准备度
4. **风险覆盖矩阵** — Case × Acceptance Steps × 风险 × 结果
5. **Oracle 完整度** — 按 oracle 类型列是否要求/验证/证据
6. **证据清单** — standard/strict 必填；light 可省略
7. **Case 执行汇总** — 按 case 列路径/结果/证据/重试
8. **场景详情** — 每 case 的 Given/When/Then + 证据引用
9. **失败分析与归因** — 6 类归因 + 置信度 + 建议动作
10. **Flaky 观察** — suspicion / 根因分类 / 治理建议
11. **资产汇总** — 复用/新增/环境/认证脚本/注册表回写
12. **Playwright 导出建议** — Case × Export Status × 脚本类型 × 阻塞原因
13. **未覆盖项与限制**
14. **总结与建议** — 证明了什么 / 没证明什么 / 下一步

## 证据级别影响

- **light**：Oracle 证据允许引用关键截图（Given + Then）；证据清单章节可省略
- **standard**：每步截图 + 完整 API 链 + 错误日志；证据清单必填
- **strict**：Oracle 证据必须包含 snapshot 文件引用；证据清单必填；全量 console 日志

## 强制规则

1. BLOCKED → 总结论不得 PASS
2. 关键 oracle 缺失 → 不得 PASS
3. 每个 FAIL 必须归因
4. 每个 case 单独结论
5. 异步超时需区分"业务失败"和"窗口不够"
6. flaky 必须标根因分类
7. 必须交代复用和沉淀
8. evidence_level=light 时：Oracle 证据允许引用关键截图（Given + Then）而非逐步截图，证据清单章节可省略
9. evidence_level=strict 时：Oracle 证据必须包含 snapshot 文件引用，证据清单章节必填
10. `third-party-noise` 只记录，不单独导致 FAIL；除非能证明它直接破坏业务链路
11. 发生重试、重跑或 trace 采集时，必须在"执行配置""Case 执行汇总""失败分析与归因"三个位置至少出现一次
12. 若当前仅做人工探索且尚未沉淀脚本，`abstraction_mode` 可填 `inline`，并在总结中说明是否建议升级为 `helper / page-object / keyword`
13. Path C 报告必须包含 acceptance step ref、console/network artifact、retry/fix history 和 export recommendation
