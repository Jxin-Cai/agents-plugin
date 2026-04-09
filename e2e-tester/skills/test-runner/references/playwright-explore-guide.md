# Playwright 探索执行指南

路径 C 的详细执行步骤。当路径决策为 C（Playwright 探索）时读取。

---

## C.1 打开浏览器
```bash
playwright-cli open {base-url}
```

## C.2 按剧本逐场景执行

对每个 Scenario：

1. **应用 Given**
   - 确认角色、登录、页面位置、数据前置状态
   - 如 Given 不成立，记为 BLOCKED 或 FAIL，不强行继续

2. **执行 When**
   - 使用 snapshot → 命令映射 → 等待条件 → 截图
   - 每步记录耗时、观察结果和异常现象

3. **验证 Then**
   - 按剧本声明的 oracle_types 分层验证：
     - UI Oracle
     - API Oracle
     - Data Oracle
     - Side Effect Oracle
   - 如果关键场景声明了 Data / Side Effect oracle，但执行中没有拿到对应证据，**不得判 PASS**

4. **记录证据**
   - 页面截图
   - 如适用，接口返回摘要、trace、导出文件、回显状态、通知页面截图

## C.3 失败分类

每个失败尽量归入以下之一：
- **product defect** — 业务逻辑或页面行为不符合预期
- **environment defect** — 环境异常、依赖服务挂掉、配置错误
- **data/setup defect** — 账号、权限、数据状态或 Mock 准备错误
- **automation defect** — 自动化脚本或定位器问题
- **requirement/oracle unclear** — 剧本或判定标准本身不清

如出现疑似偶发失败，标记为：
- **flaky suspicion: low / medium / high**

## C.4 关闭浏览器
```bash
playwright-cli close
```
