# 环境配置模板

路径：`.e2e-tests/shared/env/{env-name}.yaml`

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

blocked_scripts:
  - /piwik\.js/
  - /matomo\.js/
  - /google-analytics\.com/
  - /googletagmanager\.com/
  - /sentry\.io/
  - /browser\.sentry-cdn\.com/
  - /hotjar\.com/
  - /clarity\.ms/

deploy_scripts:
  smoke_bootstrap: scripts/deploy/smoke-bootstrap.sh
  reset_data: scripts/deploy/reset-test-data.sh

timeouts:
  api: 30000
  page_load: 60000
  async_poll: 120000
  poll_interval: 2000

feature_flags: {}
notes:
  owner: ""
  access_hint: ""
  known_traps: []
  dependencies: []
```

## 规则

- 密码用 `${ENV_VAR}` 引用，不硬编码
- 文件可提交版本控制（不含真实密码）
- 准备阶段主动检查 `.e2e-tests/shared/env/{env-name}.yaml` 是否存在；缺失时应引导用户补齐并落盘
- 缺失不阻塞——脚本 fallback 到 `process.env.BASE_URL`
- `test-prep` 做准备时读取目标环境配置确认连接、账号、第三方脚本屏蔽和部署辅助脚本
- timeouts 覆盖 quality-ledger 的默认时序基线
- `blocked_scripts` 只用于统计/监控类干扰脚本，不用于屏蔽业务依赖服务
