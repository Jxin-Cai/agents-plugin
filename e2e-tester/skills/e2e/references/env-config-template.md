# 环境配置模板

路径：`.e2e-tests/shared/env/{env-name}.yaml`

## 字段

| 分组 | 字段 | 类型 | 说明 |
|------|------|------|------|
| 基础 | name | string | 环境名 |
| 基础 | base_url | string | 前端地址 |
| 基础 | api_base_url | string | API 地址 |
| 基础 | start_urls | list | `[{name, url}]` 入口列表 |
| 认证 | auth.method | enum | bearer / cookie / basic / none |
| 认证 | auth.login_endpoint | string | 登录接口路径 |
| 认证 | auth.accounts.{role} | object | `{username, password: ${ENV_VAR}}` |
| 浏览器 | browser.device | enum | desktop / mobile / tablet |
| 浏览器 | browser.viewport | object | `{width, height}` 默认 1440×900 |
| 浏览器 | browser.locale | string | 默认 zh-CN |
| 浏览器 | browser.timezone | string | 默认 Asia/Shanghai |
| 浏览器 | browser.color_scheme | enum | light / dark / no-preference |
| 屏蔽 | blocked_scripts | list | 正则列表，默认含 piwik/matomo/GA/GTM/Sentry/Hotjar/Clarity |
| 健康 | preflight_checks | list | `[{name, type: url, target}]` |
| 部署 | deploy_scripts | object | preflight / smoke_bootstrap / reset_data / teardown 脚本路径 |
| 超时 | timeouts | object | api: 30s / page_load: 60s / async_poll: 120s / poll_interval: 2s |
| 稳定性 | stability.wait_for_network_idle | bool | 默认 true |
| 稳定性 | stability.known_async_windows | list | `[{name, max_ms, poll_interval_ms}]` |
| 其他 | feature_flags | object | 特性开关 |
| 其他 | notes | object | owner / access_hint / known_traps / dependencies |

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
