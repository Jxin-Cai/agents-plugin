# Playwright 探索执行指南

仅路径 C 时加载。探索是侦察手段：验证场景 + 提炼 API 调用链（为后续 API 脚本沉淀提供输入）。

## 步骤

### C.1 打开浏览器

开启后立即关注网络请求——每步操作触发的 API 调用都要记录。

### C.2 逐 case 执行

对每个 case：

1. **Given**：确认角色/登录/数据状态。不成立 → BLOCKED。记录认证 API。
2. **When**：`browser_snapshot` 定位 → `browser_click/type/fill_form` 操作 → `browser_wait_for` 等待。每步捕获网络请求。
3. **Then**：按 oracle_types 分层验证（UI snapshot / API 捕获 / 数据查询 / 副作用检查）。关键 oracle 缺证据 → 不判 PASS。
4. **证据**：`browser_take_screenshot` 保存到 `evidence/`。

### C.2.1 网络请求捕获

```
browser_network_requests:
  filter: "/api/"
  static: false
  requestBody: true
  requestHeaders: false
```

操作前后各调一次，对比识别新增请求。关注 method/url/status/responseBody。
POST/PUT/DELETE 记录 requestBody，认证请求记录 token 方式。

备用方案（信息不足时）：用 `browser_evaluate` 注入 fetch 拦截器记录 `window.__apiLog`。

### C.3 提炼 API 调用链摘要

每 case 执行后整理：认证 API → 业务操作 API（含参数和返回）→ 验证查询 API → 不可 API 化的操作。
此摘要是 `test-automation-builder` 生成 API 脚本的核心输入。

### C.4 失败分类

product defect / environment defect / data-setup defect / automation defect / requirement-oracle unclear
疑似偶发标记 flaky suspicion: low/medium/high。

### C.5 关闭浏览器

### C.6 输出

各 case 结论 + API 调用链摘要 + 自动化适配性判断 + 证据文件路径。
