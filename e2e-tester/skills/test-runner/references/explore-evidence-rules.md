# Playwright 探索：证据采集规则

> 逐 case 执行时的截图、网络、console 采集规则和证据清单生成。

**路径变量**：`{evidence_root}` = `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/{case-id}`

## C.2 逐 case 执行

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

## C.2.1 网络请求捕获

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

## C.2.2 证据清单生成

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

## C.3 提炼 API 调用链摘要

每 case 执行后整理：认证 API → 业务操作 API（含参数和返回）→ 验证查询 API → 不可 API 化的操作。
此摘要是 `test-automation-builder` 生成 API 脚本的核心输入。
