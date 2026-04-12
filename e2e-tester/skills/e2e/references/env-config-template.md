# 环境配置模板

路径：`.e2e-tests/env/{env-name}.yaml`

```yaml
name: {env-name}
base_url: http://localhost:3000
api_base_url: http://localhost:3000/api

auth:
  method: bearer | cookie | basic | none
  login_endpoint: /api/auth/login
  accounts:
    admin:
      username: admin
      password: ${ADMIN_PASSWORD}    # 引用环境变量
    user:
      username: test-user
      password: ${USER_PASSWORD}

timeouts:
  api: 30000
  page_load: 60000
  async_poll: 120000
  poll_interval: 2000

feature_flags: {}
notes: ""
```

## 规则

- 密码用 `${ENV_VAR}` 引用，不硬编码
- 文件可提交版本控制（不含真实密码）
- 缺失不阻塞——脚本 fallback 到 `process.env.BASE_URL`
- test-prep 做准备时读取目标环境配置确认连接和账号
- timeouts 覆盖 quality-ledger 的默认时序基线
