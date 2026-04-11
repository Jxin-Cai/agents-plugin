# 环境配置模板

`.e2e-tests/env/{env-name}.yaml` 定义测试目标环境的连接信息、认证方式和超时配置。脚本通过环境变量或读取配置文件获取这些值。

---

## 文件结构

```yaml
# .e2e-tests/env/local.yaml
name: local
base_url: http://localhost:3000
api_base_url: http://localhost:3000/api

auth:
  method: bearer          # bearer | cookie | basic | none
  login_endpoint: /api/auth/login
  accounts:
    admin:
      username: admin
      password: ${ADMIN_PASSWORD}    # 引用环境变量，不硬编码密码
    user:
      username: test-user
      password: ${USER_PASSWORD}

timeouts:
  api: 30000              # API 调用超时（ms）
  page_load: 60000        # 页面加载超时（ms）
  async_poll: 120000      # 异步轮询总超时（ms）
  poll_interval: 2000     # 轮询间隔（ms）

feature_flags: {}         # 环境特定的功能开关

notes: "本地开发环境，需先启动服务"
```

---

## 多环境示例

```
.e2e-tests/env/
├── local.yaml        # 本地开发
├── test.yaml         # 测试环境
├── staging.yaml      # 预发布环境
└── prod-mirror.yaml  # 生产镜像（只读验证）
```

---

## 脚本中引用环境配置

脚本通过 `process.env.BASE_URL` 获取当前环境的 base URL。运行时通过环境变量注入：

```bash
# API 脚本
BASE_URL=http://test.example.com npx tsx .e2e-tests/{domain}/automation/ts-001-xxx.test.ts

# E2E 脚本
BASE_URL=http://test.example.com npx playwright test .e2e-tests/{domain}/automation/ts-001-xxx.spec.ts
```

脚本内部统一使用：
```typescript
const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
```

---

## 认证约定

### Bearer Token（推荐）

```typescript
async function login(username: string, password: string): Promise<string> {
  const res = await fetch(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  const data = await res.json();
  return data.token;
}
```

### Cookie Session

E2E 脚本中通过 `page.context()` 的 `storageState` 管理；API 脚本中通过 fetch 的 cookie jar 管理。

---

## 与 test-prep 的关系

- test-prep 生成准备方案时，读取目标环境配置确认连接信息和账号可用性
- 如果目标环境的 env 配置不存在，test-prep 应建议创建
- env 配置中的 `timeouts` 覆盖 quality-ledger 中的时序基线默认值

## 维护规则

1. **密码不硬编码**：使用 `${ENV_VAR}` 引用环境变量
2. **环境配置文件可提交到版本控制**：因为不含真实密码
3. **新环境按需创建**：不要求预创建所有环境配置
4. **缺失不阻塞**：env 配置不存在时，脚本使用 `process.env.BASE_URL` 默认值
