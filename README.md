# agents-plugin

为不同 Agent 角色准备的即插即用技能组插件。

## 安装

### 方式一：Claude Code CLI 安装（推荐）

```bash
claude plugin add git@github.com:Jxin-Cai/agents-plugin.git
```

### 方式二：手动安装

1. 克隆仓库到本地插件目录：

```bash
git clone git@github.com:Jxin-Cai/agents-plugin.git ~/.claude/plugins/agents-plugin
```

2. 在 `~/.claude/settings.json` 中注册插件：

```json
{
  "plugins": [
    "~/.claude/plugins/agents-plugin"
  ]
}
```

## 插件市场

当前可用的 Agent 技能组：

| 插件名 | 说明 | 版本 |
|--------|------|------|
| `product-manager` | 产品经理：结构化需求发现、头脑风暴、需求澄清与 PRD 生成 | 3.0.2 |
| `ask-buddy` | 本地优先的只读个人助理：渐进交互、分层记忆、飞书简报与可信研究 | 2.6.0 |

## ask-buddy

Ask Buddy 只读取工作区；唯一允许写入的位置是当前项目的 `.ask-buddy/` 记忆目录。它采用 profile、session、daily、curated memory、playbook、pending 六层状态模型：明确事实可保存，推断和自学习候选必须先经用户确认。内置零依赖、本地运行的 Memory MCP，提供分层检索、精确读取、状态检查和待确认候选暂存；检索在实现层排除 pending、备份、符号链接和失效条目。另默认集成固定版本的 OneSearch MCP（DuckDuckGo），用于实时资料检索，并关闭对本机、回环和内网地址的抓取。

主要技能：

| 技能 | 说明 |
|------|------|
| `qa-guide` | 按问题类型路由本地检索、稳定知识与可信联网研究 |
| `init` | 建立最小用户档案、记忆偏好和联网偏好 |
| `memory-sync` | 保存带来源、核实时间和有效期的长期记忆 |
| `memory-control` | 查看、导出、忘记、清空或关闭长期记忆 |
| `instincts` | 基于明确证据适配回答风格和关注重点 |
| `personal-briefing` | 按需只读汇总日历、任务、邮件和当前工作焦点 |
| `learning-loop` | 将成功或失败经验暂存为候选，经用户批准后形成可复用 playbook |

交互默认采用“先回应、后追问”：首次使用不会用初始化问卷阻塞用户，每轮最多提出一个关键问题；复杂任务仅在出现新证据、风险或方向变化时更新进度。PreCompact hook 会在上下文压缩前重新注入当前目标、纠正和 open-loop，减少长对话中的状态丢失。

安装后可在 Claude Code 中用 `/mcp` 检查 `ask-buddy-memory`、`feishu-openapi-readonly`、`feishu-assistant-readonly` 和 `one-search`，用 `/hooks` 检查只读防护。Memory MCP 只依赖 Python 3、不会联网；首次启用 MCP 时 Claude Code 会要求信任项目配置。

### 飞书接入

Ask Buddy 使用用户身份读取个人日历、任务和邮箱。飞书官方 OpenAPI MCP 负责日历、任务详情和忙闲查询；本地只读桥接通过飞书官方 CLI 提供日程摘要、我的任务、邮件摘要和单封纯文本读取。插件不暴露创建日程、修改任务、发送邮件或删除数据的工具。

1. 在[飞书开放平台](https://open.feishu.cn/app)创建企业自建应用，把 OAuth 重定向地址设为 `http://localhost:3000/callback`。
2. 为应用开通最小读取权限：`calendar:calendar:read`、`calendar:calendar.event:read`、`calendar:calendar.free_busy:read`、`task:task:read`、`task:tasklist:read`、`mail:user_mailbox:readonly`、`mail:user_mailbox.message:readonly`、`mail:user_mailbox.message.body:read` 和 `offline_access`。
3. 在启动 Claude Code 的 shell 中设置 `ASK_BUDDY_LARK_APP_ID`、`ASK_BUDDY_LARK_APP_SECRET`；不要把值写入仓库或提交到 Git。
4. 安装并初始化官方 CLI，再按最小范围完成用户授权：

```bash
npm install -g @larksuite/cli@1.0.85
lark-cli config init --new
lark-cli auth login --scope "calendar:calendar:read calendar:calendar.event:read calendar:calendar.free_busy:read task:task:read task:tasklist:read mail:user_mailbox:readonly mail:user_mailbox.message:readonly mail:user_mailbox.message.body:read offline_access"
```

重启 Claude Code 后运行 `/mcp` 检查连接。可用“今天有什么安排”“整理我未完成的任务”“总结最近未读邮件”验证三个入口。邮箱和日程内容只用于当前回答，默认不写入长期记忆。

## product-manager

产品经理 Agent 技能组，提供完整的需求分析工作流。

### 命令

| 命令 | 说明 |
|------|------|
| `/pa` | 启动完整产品分析流程（SC → BR → CL → GP） |

### 技能

| 技能 | 说明 |
|------|------|
| `scan-context` | 扫描项目代码和文档，提取领域知识 |
| `brainstorm-requirements` | 收敛式头脑风暴，补全功能点和边界条件 |
| `clarify-requirements` | 逐项追问边界条件和三条链路 |
| `generate-prd` | 将完善的需求写成极简 PRD 文档 |
| `pa` | 按顺序执行完整流程 |

## 项目结构

```
agents-plugin/
├── .claude-plugin/
│   └── marketplace.json          # 插件市场清单
├── product-manager/              # 产品经理 Agent
│   ├── .claude-plugin/
│   │   └── plugin.json           # 插件配置
│   ├── skills/                   # 技能定义
│   ├── commands/                 # 命令入口
│   ├── hooks/                    # 生命周期钩子
│   └── prompts/                  # Agent 提示词
└── <new-agent>/                  # 扩展：新增 Agent 子目录即可
    └── .claude-plugin/
        └── plugin.json
```

## 扩展新 Agent

1. 在根目录新建 Agent 子目录（如 `game-designer/`）
2. 在子目录内创建 `.claude-plugin/plugin.json` 声明插件信息
3. 按照 `product-manager/` 的结构组织 `skills/`、`commands/`、`hooks/`、`prompts/`
4. 在根目录 `.claude-plugin/marketplace.json` 中注册插件
