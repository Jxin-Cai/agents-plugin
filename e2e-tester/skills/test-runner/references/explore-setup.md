# Playwright 探索：环境准备

> 仅路径 C 时加载。包含证据级别读取、浏览器启动和第三方脚本屏蔽。

**路径变量**：`{evidence_root}` = `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}`。执行前必须拼出完整值。

## C.0 读取证据级别

从 `index.md` frontmatter 读取 `evidence_level`（light / standard / strict）。缺失时视为 `standard`。

先创建证据目录结构：`mkdir -p {evidence_root}/{screenshots,snapshots,videos,api,network,console}`

再按级别补充子目录：
- `screenshots/` — 所有级别
- `api/` — 所有级别
- `network/` — standard / strict 或失败时
- `console/` — standard 出错时、strict 全程
- `videos/` — 按需录屏
- `snapshots/` — strict 或页面探索关键点
- strict 时立即调用 `browser_console_messages(level: "debug", filename: "{evidence_root}/console-full.txt")` 开始全量日志采集

## C.1 打开浏览器并自动探索

从 `shared/env/{target_env}.yaml` 读取 `browser`、`start_urls`、`preflight_checks` 和 `stability`。先执行 preflight；失败则 BLOCKED。

打开页面后先调用 `browser_snapshot` 建立可访问性视图，再决定点击/输入目标。不要盲点坐标或依赖截图猜测。开启后立即关注网络请求——每步操作触发的 API 调用都要记录。

## C.1.1 屏蔽第三方干扰脚本

读取 `.e2e-tests/shared/env/{target_env}.yaml` 中的 `blocked_scripts`。若存在，优先使用环境配置中的规则；若缺失，使用默认统计/监控脚本屏蔽清单。

通过 `browser_run_code` 设置路由规则，拦截已知的第三方统计/监控脚本：

```javascript
async (page) => {
  await page.route(/\/(piwik|matomo)\.js/, route => route.abort());
  await page.route(/google-analytics\.com|googletagmanager\.com/, route => route.abort());
  await page.route(/sentry\.io|browser\.sentry-cdn\.com/, route => route.abort());
  await page.route(/hotjar\.com|clarity\.ms/, route => route.abort());
}
```

**原则**：
- 只屏蔽统计/监控类脚本，不屏蔽业务依赖的第三方服务
- 控制台日志中来自被屏蔽域名的错误标记为 `[third-party-noise]`
- `[third-party-noise]` 不计入失败判定，不作为 oracle 缺失的依据
- 若第三方脚本异常导致页面关键业务功能不可用，再按真实产品问题处理，不因为"第三方"而自动忽略
