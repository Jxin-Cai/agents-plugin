# Playwright 探索：失败处理与输出

> 失败分类、guardrails、浏览器关闭和最终输出格式。

## C.4 失败分类与 guardrails

失败类型：product defect / environment defect / data-setup defect / automation defect / requirement-oracle unclear / third-party-noise。疑似偶发标记 flaky suspicion: low/medium/high。

重试规则：
- 每 case 最多一次同条件重试；只允许页面未稳定、短暂网络抖动、flaky suspicion 为 medium/high 时触发。
- 浏览器会话最多重建一次；重建后仍失败则停止并归因。
- 权限不足、业务状态错误、真实产品报错、oracle 不清、preflight 失败不重试。
- automation defect 才建议交给 `fix-script`，并附上报告、evidence manifest、console/network artifact。

## C.5 关闭浏览器

## C.6 输出

各 case 结论 + API 调用链摘要 + 自动化适配性判断 + 证据文件路径列表。

输出必须包含：
- 证据根目录路径（`{evidence_root}` 的完整值）
- 每 case 的截图文件列表
- 每 case 的 API 记录文件列表
- evidence_level 实际执行级别
- acceptance step ref 到 artifact 的映射
- console/network artifact 列表
- retry/restart/fix history
- 第三方脚本屏蔽规则来源（env/default）
- 认证 API 调用链摘要（供认证脚本沉淀使用）
- export recommendation：none / recommended / blocked，及原因
