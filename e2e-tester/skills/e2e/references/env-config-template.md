# 环境配置模板

路径：`.e2e-tests/shared/env/{env-name}.yaml`

```yaml
name: {env-name}
base_url: http://localhost:3000
api_base_url: http://localhost:3000/api
start_urls:
  - name: home
    url: http://localhost:3000
  - name: target-flow
    url: http://localhost:3000/{path}

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

browser:
  device: desktop | mobile | tablet
  viewport:
    width: 1440
    height: 900
  locale: zh-CN
  timezone: Asia/Shanghai
  color_scheme: light | dark | no-preference

blocked_scripts:
  - /piwik\.js/
  - /matomo\.js/
  - /google-analytics\.com/
  - /googletagmanager\.com/
  - /sentry\.io/
  - /browser\.sentry-cdn\.com/
  - /hotjar\.com/
  - /clarity\.ms/

preflight_checks:
  - name: frontend-health
    type: url
    target: ${BASE_URL}
  - name: api-health
    type: url
    target: ${API_BASE_URL}/health

deploy_scripts:
  preflight: scripts/deploy/preflight.sh
  smoke_bootstrap: scripts/deploy/smoke-bootstrap.sh
  reset_data: scripts/deploy/reset-test-data.sh
  teardown: scripts/deploy/teardown-test-data.sh

timeouts:
  api: 30000
  page_load: 60000
  async_poll: 120000
  poll_interval: 2000

stability:
  wait_for_network_idle: true
  known_async_windows:
    - name: eventual-consistency
      max_ms: 120000
      poll_interval_ms: 2000

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
- `test-prep` 做准备时读取目标环境配置确认连接、账号、start_urls、browser profile、第三方脚本屏蔽、preflight checks 和部署辅助脚本
- timeouts 覆盖 quality-ledger 的默认时序基线
- `blocked_scripts` 只用于统计/监控类干扰脚本，不用于屏蔽业务依赖服务
- `deploy_scripts` 记录可复跑命令或仓库相对路径，不写个人机器绝对路径
- 所有密钥、账号密码、token 只写 `${ENV_VAR}` 占位，不写真实值
