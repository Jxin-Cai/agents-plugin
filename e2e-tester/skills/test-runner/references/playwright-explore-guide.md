# Playwright 探索执行指南

仅路径 C 时加载。探索是侦察手段：真实浏览器验证场景 + 执行自然语言/Markdown 验收步骤 + 采集截图/console/network + 提炼 API 调用链（为后续 Playwright/API 脚本沉淀提供输入）。

## 路径纪律

所有 `browser_take_screenshot` 的 `filename` 参数必须使用以 `.e2e-tests/` 开头的完整路径。
**禁止使用纯文件名或相对路径**。每张截图的路径模式：
```
.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}/screenshots/{name}.png
```

以下用 `{evidence_root}` 代替 `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}`。
执行前必须从 run 上下文拼出 `{evidence_root}` 的完整值。

## 步骤

### C.0 读取证据级别

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

### C.1 打开浏览器并自动探索

从 `shared/env/{target_env}.yaml` 读取 `browser`、`start_urls`、`preflight_checks` 和 `stability`。先执行 preflight；失败则 BLOCKED。

打开页面后先调用 `browser_snapshot` 建立可访问性视图，再决定点击/输入目标。不要盲点坐标或依赖截图猜测。开启后立即关注网络请求——每步操作触发的 API 调用都要记录。

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
- 若第三方脚本异常导致页面关键业务功能不可用，再按真实产品问题处理，不因为"第三方"而自动忽略

### C.2 逐 case 执行

对每个 case：

先读取 scenario 的 Step Mapping。将用户原始验收步骤映射为 `AS-001`、`AS-002` 等 step ref；每次操作、截图、console/network 记录都标注对应 step ref。

1. **Given**：确认角色/登录/数据状态。不成立 → BLOCKED。记录认证 API、账号角色、start URL、preflight 结果。
   - 截图：`browser_take_screenshot(filename: "{evidence_root}/screenshots/given-verified.png")`（所有级别）

2. **When**：`browser_snapshot` 定位 → `browser_click/type/fill_form/select_option` 操作 → `browser_wait_for` 等待。每一步优先使用 role/text/testid 等稳定目标，避免脆弱 CSS 层级。

   按 evidence_level 分级采集：

   **light**：
   - 不逐步截图
   - 仅在整个 When 阶段的核心业务操作前后各调一次 `browser_network_requests`

   **standard**：
   - 每个 When 步骤完成后截图：`browser_take_screenshot(filename: "{evidence_root}/screenshots/step-{NN}-{slug}.png")`
   - 每步操作前后调用 `browser_network_requests`（见 C.2.1）
   - 出现错误或 oracle 未满足时调用 `browser_console_messages(level: "error", filename: "{evidence_root}/console/step-{NN}-error.txt")`

   **strict**：
   - 每个原子操作（click/type/fill/select/等待完成）后截图，使用子步骤编号：`{evidence_root}/screenshots/step-{NN}a-{slug}.png`、`step-{NN}b-{slug}.png`
   - 每个原子操作后调用 `browser_snapshot(filename: "{evidence_root}/snapshots/step-{NN}-snapshot.md")`
   - 每步操作前后调用 `browser_network_requests`（见 C.2.1）
   - 出现错误或 oracle 未满足时调用 `browser_console_messages(level: "error", filename: "{evidence_root}/console/step-{NN}-error.txt")`

3. **Then**：按 oracle_types 分层验证（UI snapshot / API 捕获 / 数据查询 / 副作用检查）。关键 oracle 缺证据 → 不判 PASS。
   - 截图：`browser_take_screenshot(filename: "{evidence_root}/screenshots/then-result.png")`（所有级别）
   - standard 出错时：`browser_console_messages(level: "error", filename: "{evidence_root}/console/then-error.txt")`
   - strict：`browser_console_messages(level: "debug", filename: "{evidence_root}/console/console-full.txt")` 刷新全量日志
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
- 保存为 `{evidence_root}/api/key-api-{slug}.json`，内容为 `{request: {method, url, body}, response: {status, body}}`；原始 network 摘要保存到 `{evidence_root}/network/key-network-{slug}.txt`

**standard / strict**：
- 每步操作前后各调一次，对比识别新增请求
- 每个新增 API 调用单独保存为 `{evidence_root}/api/step-{NN}-{METHOD}-{slug}.json`，对应原始 network 片段保存到 `{evidence_root}/network/step-{NN}-{slug}.txt`
- POST/PUT/DELETE 记录 requestBody，认证请求记录 token 方式

备用方案（信息不足时）：用 `browser_evaluate` 注入 fetch 拦截器记录 `window.__apiLog`。

### C.2.2 证据清单生成

每 case 执行完毕后：

**light**：不生成清单文件（证据文件少，直接在报告中引用）。

**standard / strict**：生成 `{evidence_root}/evidence-manifest.md`：

```markdown
# 证据清单: {case-id}

| 序号 | 类型 | 文件路径 | 步骤 | Acceptance Step | 说明 |
|------|------|----------|------|-----------------|------|
| 1 | screenshot | screenshots/given-verified.png | Given | AS-000 | 前置状态确认 |
| 2 | screenshot | screenshots/step-01-click-submit.png | When-1 | AS-001 | 提交按钮点击后 |
| 3 | api | api/step-01-POST-create-order.json | When-1 | AS-001 | 创建订单请求/响应 |
| ... | | | | | |
```

### C.3 提炼 API 调用链摘要

每 case 执行后整理：认证 API → 业务操作 API（含参数和返回）→ 验证查询 API → 不可 API 化的操作。
此摘要是 `test-automation-builder` 生成 API 脚本的核心输入。

### C.4 失败分类与 guardrails

失败类型：product defect / environment defect / data-setup defect / automation defect / requirement-oracle unclear / third-party-noise。疑似偶发标记 flaky suspicion: low/medium/high。

重试规则：
- 每 case 最多一次同条件重试；只允许页面未稳定、短暂网络抖动、flaky suspicion 为 medium/high 时触发。
- 浏览器会话最多重建一次；重建后仍失败则停止并归因。
- 权限不足、业务状态错误、真实产品报错、oracle 不清、preflight 失败不重试。
- automation defect 才建议交给 `fix-script`，并附上报告、evidence manifest、console/network artifact。

### C.5 关闭浏览器

### C.6 输出

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
