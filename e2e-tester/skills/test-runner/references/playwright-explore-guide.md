# Playwright 探索执行指南

仅路径 C 时加载。探索是侦察手段：验证场景 + 提炼 API 调用链（为后续 API 脚本沉淀提供输入）。

## 步骤

### C.0 读取证据级别

从 `index.md` frontmatter 读取 `evidence_level`（light / standard / strict）。缺失时视为 `standard`。

证据根目录：`.e2e-tests/tasks/{date}-{slug}/evidence/{YYYY-MM-DD}/TS-{NNN}-C{N}/`（当前日期 + 场景编号 + case 编号）。

先创建证据目录结构：`mkdir -p .e2e-tests/tasks/{date}-{slug}/evidence/{YYYY-MM-DD}/TS-{NNN}-C{N}/{screenshots,videos,api}`

再按级别补充子目录：
- `screenshots/` — 所有级别
- `api/` — 所有级别
- `videos/` — 按需录屏
- `snapshots/` — 仅 strict
- strict 时立即调用 `browser_console_messages(level: "debug", filename: "console-full.txt")` 开始全量日志采集

### C.1 打开浏览器

开启后立即关注网络请求——每步操作触发的 API 调用都要记录。

### C.1.1 屏蔽第三方干扰脚本

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
- 若第三方脚本异常导致页面关键业务功能不可用，再按真实产品问题处理，不因为“第三方”而自动忽略

### C.2 逐 case 执行

对每个 case：

1. **Given**：确认角色/登录/数据状态。不成立 → BLOCKED。记录认证 API。
   - 截图：`browser_take_screenshot(filename: "screenshots/given-verified.png")`（所有级别）

2. **When**：`browser_snapshot` 定位 → `browser_click/type/fill_form` 操作 → `browser_wait_for` 等待。

   按 evidence_level 分级采集：

   **light**：
   - 不逐步截图
   - 仅在整个 When 阶段的核心业务操作前后各调一次 `browser_network_requests`

   **standard**：
   - 每个 When 步骤完成后截图：`browser_take_screenshot(filename: "screenshots/step-{NN}-{slug}.png")`
   - 每步操作前后调用 `browser_network_requests`（见 C.2.1）

   **strict**：
   - 每个原子操作（click/type/fill/select/等待完成）后截图，使用子步骤编号：`screenshots/step-{NN}a-{slug}.png`、`step-{NN}b-{slug}.png`
   - 每个原子操作后调用 `browser_snapshot(filename: "snapshots/step-{NN}-snapshot.md")`
   - 每步操作前后调用 `browser_network_requests`（见 C.2.1）

3. **Then**：按 oracle_types 分层验证（UI snapshot / API 捕获 / 数据查询 / 副作用检查）。关键 oracle 缺证据 → 不判 PASS。
   - 截图：`browser_take_screenshot(filename: "screenshots/then-result.png")`（所有级别）
   - standard 出错时：`browser_console_messages(level: "error", filename: "console-error.txt")`
   - strict：`browser_console_messages(level: "debug", filename: "console-full.txt")` 刷新全量日志
   - 若控制台日志包含被屏蔽域名报错，在报告中归类到 `third-party-noise`，不计入失败归因

### C.2.1 网络请求捕获

基础参数不变：
```
browser_network_requests:
  filter: "/api/"
  static: false
  requestBody: true
  requestHeaders: false
```

按 evidence_level 差异化保存：

**light**：
- 仅在核心业务操作前后各调一次
- 从 diff 中识别最关键的业务 API（POST/PUT/DELETE 优先）
- 保存为 `api/key-api-{slug}.json`，内容为 `{request: {method, url, body}, response: {status, body}}`

**standard / strict**：
- 每步操作前后各调一次，对比识别新增请求
- 每个新增 API 调用单独保存为 `api/step-{NN}-{METHOD}-{slug}.json`
- POST/PUT/DELETE 记录 requestBody，认证请求记录 token 方式

备用方案（信息不足时）：用 `browser_evaluate` 注入 fetch 拦截器记录 `window.__apiLog`。

### C.2.2 证据清单生成

每 case 执行完毕后：

**light**：不生成清单文件（证据文件少，直接在报告中引用）。

**standard / strict**：生成 `evidence-manifest.md`：

```markdown
# 证据清单: TS-{NNN}-C{N}

| 序号 | 类型 | 文件路径 | 步骤 | 说明 |
|------|------|----------|------|------|
| 1 | screenshot | screenshots/given-verified.png | Given | 前置状态确认 |
| 2 | screenshot | screenshots/step-01-click-submit.png | When-1 | 提交按钮点击后 |
| 3 | api | api/step-01-POST-create-order.json | When-1 | 创建订单请求/响应 |
| ... | | | | |
```

### C.3 提炼 API 调用链摘要

每 case 执行后整理：认证 API → 业务操作 API（含参数和返回）→ 验证查询 API → 不可 API 化的操作。
此摘要是 `test-automation-builder` 生成 API 脚本的核心输入。

### C.4 失败分类

product defect / environment defect / data-setup defect / automation defect / requirement-oracle unclear / third-party-noise
疑似偶发标记 flaky suspicion: low/medium/high。

### C.5 关闭浏览器

### C.6 输出

各 case 结论 + API 调用链摘要 + 自动化适配性判断 + 证据文件路径列表。

输出必须包含：
- 证据根目录路径
- 每 case 的截图文件列表
- 每 case 的 API 记录文件列表
- evidence_level 实际执行级别
- 第三方脚本屏蔽规则来源（env/default）
