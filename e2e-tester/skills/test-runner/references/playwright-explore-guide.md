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
   - 使用 snapshot → 命令映射 → 等待条件 → 截图
   - 每步记录耗时、观察结果和异常现象
   - **每个操作后记录触发的网络请求**：
     - 请求方法和 URL（如 `POST /api/orders`）
     - 关键请求参数
     - 响应状态码和关键返回字段
     - 请求顺序和依赖关系

3. **验证 Then**
   - 按剧本声明的 oracle_types 分层验证：
     - UI Oracle
     - API Oracle
     - Data Oracle
     - Side Effect Oracle
   - 如果关键场景声明了 Data / Side Effect oracle，但执行中没有拿到对应证据，**不得判 PASS**
   - **记录验证过程中查询用的 API（如 GET 列表、GET 详情）**

4. **记录证据**
   - 页面截图
   - 如适用，接口返回摘要、trace、导出文件、回显状态、通知页面截图

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
