# Available Providers

本文件供 `req-setup` skill 参考。实际可用 provider 列表由 `providers/` 目录动态扫描获得。

## Jira (Server/Data Center)

- **Key**: `jira`
- **认证**: Personal Access Token (PAT)
- **API**: REST API v2 (Server/DC) 或 v3 (Cloud)
- **Issue Key 格式**: `PROJECT-NUMBER`（如 `APRICOT-1042627`）
- **首次配置需输入**: `base_url`, `token`

## Linear

- **Key**: `linear`
- **认证**: API Key
- **API**: GraphQL API
- **Issue Key 格式**: `TEAM-NUMBER`（如 `ENG-123`）
- **首次配置需输入**: `api_key`

## GitHub Issues

- **Key**: `github-issues`
- **认证**: `gh` CLI 已登录态，或首次配置时输入 GitHub Token（PAT / GitHub App）
- **实现方式**: 基于 `gh` CLI（`gh issue view/comment/list`）
- **Issue Key 格式**: `owner/repo#NUMBER`（如 `org/repo#42`），或在配置了默认仓库后使用 `#NUMBER` / `NUMBER`
- **首次配置可输入**: `repo`, `token`
- **可用操作**: `fetch`, `comment`, `search`
- **不支持**: `transitions`, `transition`, `attach`

## 候选扩展 Provider

- **Azure DevOps Boards** — 官方 `azure-devops-mcp`，也可走 `az boards` CLI
- **Shortcut** — 官方 `mcp-server-shortcut`
- **YouTrack** — 社区 `youtrack-mcp`
- **Linear** — 官方 MCP 可接入，当前本地 provider 仍为桩实现

## 添加新 Provider

在 `providers/` 目录下创建新目录，包含：
1. `provider.yaml` — 元数据和连接字段声明
2. `api.sh` — 实现 provider 合约中的一个或多个操作；未支持操作返回 `exit 2`
