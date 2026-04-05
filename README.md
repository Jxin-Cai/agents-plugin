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
| `product-manager` | 产品经理：结构化需求发现、头脑风暴、需求澄清与 PRD 生成 | 1.0.0 |

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
