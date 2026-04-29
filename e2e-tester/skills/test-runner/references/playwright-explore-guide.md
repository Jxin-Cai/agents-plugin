# Playwright 探索执行指南

仅路径 C 时加载。按执行阶段加载对应子文件，不要一次性全部加载。

## 路径纪律

所有 `browser_take_screenshot` 的 `filename` 参数必须使用以 `.e2e-tests/` 开头的完整路径。
**禁止使用纯文件名或相对路径**。路径模式：`.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots/{name}.png`

`{evidence_root}` = `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}`，执行前必须拼出完整值。

## 子文件按需加载

| 阶段 | 文件 | 加载时机 |
|------|------|---------|
| 环境准备 | `explore-setup.md` | 开始 Path C 前，读取证据级别、打开浏览器、屏蔽第三方脚本 |
| 证据采集 | `explore-evidence-rules.md` | 逐 case 执行时，按 evidence_level 分级采集截图/网络/console |
| 失败与输出 | `explore-failure-and-output.md` | 执行完成或失败时，归因、关闭浏览器、整理输出 |
