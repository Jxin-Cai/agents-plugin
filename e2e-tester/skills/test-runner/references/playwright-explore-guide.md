# Playwright 探索执行指南

路径 C 的详细执行步骤。当路径决策为 C（Playwright 探索）时读取。

**核心定位**：Playwright 探索是侦察手段，不是最终产物。探索的双重目标：
1. 验证业务场景是否通过
2. 发现并记录 API 调用链，为后续沉淀纯 API 脚本提供知识

---

## C.1 打开浏览器（开启网络拦截）
```bash
playwright-cli open {base-url}
```

打开后立即关注浏览器的网络请求——后续每一步操作触发的 API 调用都是需要记录的关键信息。

## C.2 按剧本逐场景执行

对每个 Scenario：

1. **应用 Given**
   - 确认角色、登录、页面位置、数据前置状态
   - 如 Given 不成立，记为 BLOCKED 或 FAIL，不强行继续
   - **记录登录过程触发的 API（认证端点、token 获取方式）**

2. **执行 When**
   - 使用 `browser_snapshot` 获取页面快照 → 定位目标元素 → 使用 `browser_click` / `browser_type` / `browser_fill_form` 执行操作 → 使用 `browser_wait_for` 等待状态变化
   - 每步记录耗时、观察结果和异常现象
   - **每个操作后捕获网络请求**（具体方法见 C.2.1）

3. **验证 Then**
   - 按剧本声明的 oracle_types 分层验证：
     - UI Oracle：使用 `browser_snapshot` 检查页面状态
     - API Oracle：通过捕获的网络请求验证
     - Data Oracle：通过查询接口验证数据状态
     - Side Effect Oracle：检查通知、导出等副作用
   - 如果关键场景声明了 Data / Side Effect oracle，但执行中没有拿到对应证据，**不得判 PASS**
   - **记录验证过程中查询用的 API（如 GET 列表、GET 详情）**

4. **记录证据**
   - 使用 `browser_take_screenshot` 截图保存到 `.e2e-tests/{domain}/evidence/` 目录
   - 如适用，接口返回摘要、trace、导出文件、回显状态、通知页面截图

### C.2.1 网络请求捕获方法

每个 When 步骤执行后，使用 `browser_network_requests` 工具获取触发的网络请求：

```
工具: browser_network_requests
参数:
  filter: "/api/"        # 只关注业务接口，过滤掉静态资源
  static: false          # 不包含静态资源
  requestBody: true      # 包含请求体（用于记录参数）
  requestHeaders: false  # 通常不需要请求头
```

**捕获要点**：
- 操作前后各调用一次 `browser_network_requests`，通过对比识别新增请求
- 关注请求的 `method`、`url`、`status`、`responseBody` 中的关键字段
- 对于 POST/PUT/DELETE 请求，记录请求参数（requestBody）
- 对于认证请求，记录 token 获取方式
- 如果 `browser_network_requests` 返回过多请求，用更精确的 filter（如 `"/api/orders"`)

**替代方案**（当 network_requests 信息不足时）：
使用 `browser_evaluate` 在页面注入 fetch 拦截器：
```javascript
工具: browser_evaluate
参数:
  function: |
    () => {
      window.__apiLog = window.__apiLog || [];
      const origFetch = window.fetch;
      window.fetch = async (...args) => {
        const res = await origFetch(...args);
        const url = typeof args[0] === 'string' ? args[0] : args[0].url;
        if (url.includes('/api/')) {
          const clone = res.clone();
          const body = await clone.json().catch(() => null);
          window.__apiLog.push({ url, method: args[1]?.method || 'GET', status: res.status, body });
        }
        return res;
      };
      return 'API interceptor installed';
    }
```

读取拦截记录：
```javascript
工具: browser_evaluate
参数:
  function: |
    () => {
      const log = window.__apiLog || [];
      window.__apiLog = [];  // 清空已读记录
      return JSON.stringify(log, null, 2);
    }
```

## C.3 提炼 API 调用链摘要

每个 Scenario 执行完毕后，整理一份 **API 调用链摘要**，包含：

```markdown
### API 调用链: {Scenario 名称}

#### 认证
- POST /api/auth/login → 200, 返回 { token }

#### 业务操作
1. POST /api/orders → 201, 返回 { id, status: "pending" }
   - 请求: { productId, quantity, ... }
2. GET /api/orders/{id} → 200, 确认状态
   - 返回: { id, status: "pending", ... }

#### 验证查询
- GET /api/orders?status=pending → 200, 列表中包含新订单

#### 不可 API 化的操作
- {如有：哪些操作只能通过 UI 完成，无对应 API}
```

这份摘要是后续 `test-automation-builder` 生成纯 API 脚本的核心输入。

## C.4 失败分类

每个失败尽量归入以下之一：
- **product defect** — 业务逻辑或页面行为不符合预期
- **environment defect** — 环境异常、依赖服务挂掉、配置错误
- **data/setup defect** — 账号、权限、数据状态或 Mock 准备错误
- **automation defect** — 自动化脚本或定位器问题
- **requirement/oracle unclear** — 剧本或判定标准本身不清

如出现疑似偶发失败，标记为：
- **flaky suspicion: low / medium / high**

## C.5 关闭浏览器
```bash
playwright-cli close
```

## C.6 输出

探索报告中必须包含：
1. 各 Scenario 的通过/失败结论及证据
2. **完整的 API 调用链摘要**（C.3 的输出）
3. **自动化适配性判断**：哪些操作可以纯 API 化，哪些只能 UI 操作
4. **证据文件路径**：截图存放在 `.e2e-tests/{domain}/evidence/` 下
