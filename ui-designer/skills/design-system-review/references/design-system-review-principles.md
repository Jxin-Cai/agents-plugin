# 设计系统评审原则

本文档定义了设计系统评审阶段必须遵循的原则。用这些原则检查设计系统的健康度。

---

## 1. 组件清单与一致性

设计系统的核心是组件库。组件清单审查是评审的基础。

### 组件完整性
- 所有页面使用的 UI 元素是否都在组件库中有对应？
- 组件是否覆盖了必要的变体（primary / secondary / danger / ghost 等）？
- 组件是否覆盖了所有交互状态（default / hover / focus / active / disabled / loading / error）？
- 空状态（Empty State）是否被当作组件处理？

### 重复组件检测
- 是否存在功能重叠的组件？（如两种不同实现的 Dialog/Modal）
- 近似组件之间的差异是否有设计意图？还是历史遗留？
- 评估合并或废弃重复组件的可行性

### 组件 API 一致性
- 同类组件的 Props/API 是否遵循统一模式？
  - 如：所有组件用 `size="sm|md|lg"` 而非混用 `small/medium/large`
  - 如：所有颜色相关 Props 统一用 `variant` 而非混用 `type/color/kind`
- 事件命名是否一致？（如统一用 `onChange` / `onClose`）
- 插槽/子组件模式是否一致？

---

## 2. Token 架构与使用规范

设计 Token 是设计系统的"原子"——所有视觉属性的单一来源。

### Token 三层架构
```
全局 Token（Global）     → 原始值定义
  如：blue-500 = #3B82F6

语义 Token（Semantic）   → 用途映射
  如：color-primary = blue-500
     color-danger = red-500

组件 Token（Component）  → 组件级覆盖
  如：button-primary-bg = color-primary
     button-danger-bg = color-danger
```

### Token 使用规范
- **零硬编码原则**：组件代码中不应出现原始颜色值、像素值、字体名称
- **语义化命名**：Token 名称反映用途而非视觉属性（`color-primary` 优于 `blue`）
- **单一来源**：每个设计决策只在一处定义，其他地方引用
- **主题友好**：Token 架构支持深色模式/多主题切换

### 硬编码检测策略
搜索以下模式标记硬编码值：
- 颜色：`#[0-9a-fA-F]{3,8}`、`rgb(`、`rgba(`、`hsl(`
- 间距：CSS 中的 `px`/`rem`/`em` 直接使用（排除 Token 引用）
- 字体：`font-family:` 直接指定字体名
- 阴影：`box-shadow:` 直接使用数值

---

## 3. 代码-设计一致性（Design-Code Parity）

设计稿和代码实现之间的偏差（Design Drift）是设计系统劣化的主要原因。

### 检查维度
| 维度 | 允许偏差 | 需要关注 | 严重偏差 |
|------|----------|----------|----------|
| 颜色 | Token 映射一致 | 1-2 处非标准色 | 大量硬编码颜色 |
| 间距 | 遵循 4px/8px 网格 | 偶尔使用非网格值 | 间距随意无规律 |
| 字体 | 字号/行高/字重完全匹配 | 行高有微调 | 字号随意定义 |
| 圆角 | 统一使用 Token | 1-2 处自定义圆角 | 圆角值无规律 |
| 阴影 | 使用定义好的层级 | 偶尔自定义阴影 | 阴影值混乱 |
| 动画 | 统一时长和缓动曲线 | 个别组件自定义 | 动画不一致 |

### 偏差溯源
发现偏差时追问：
- 这是有意的定制，还是无意的偏离？
- 如果是定制，是否应该回馈到设计系统中？
- 如果是偏离，偏离了多久？影响了多少页面？

---

## 4. 命名规范与组织结构

命名是设计系统可维护性的关键。

### 组件命名规范
- **PascalCase**（React/Vue）或 **kebab-case**（Web Components/CSS）
- 名称反映组件职责而非视觉样式（`AlertDialog` 优于 `RedPopup`）
- 复合组件使用一致的嵌套命名（`Card` / `Card.Header` / `Card.Body`）
- 避免使用数字后缀表示版本（`Button2` 是设计债务信号）

### 目录结构
推荐的组件库组织方式：
```
components/
├── atoms/       # 原子组件：Button, Input, Icon, Badge
├── molecules/   # 分子组件：FormField, SearchBar, Card
├── organisms/   # 有机体组件：Header, Sidebar, DataTable
├── templates/   # 模板组件：PageLayout, FormLayout
└── tokens/      # 设计 Token 定义
```

---

## 5. 文档与治理

设计系统不是交付一次就完成的项目，而是持续维护的产品。

### 组件文档标准
每个组件的文档应包含：
- **用途说明**：这个组件什么时候用、解决什么问题
- **使用示例**：至少包含最常见的 2-3 种用法
- **API 文档**：所有 Props/Slots/Events 的说明
- **Do's & Don'ts**：正确和错误的使用方式对比
- **无障碍说明**：ARIA 属性、键盘交互、屏幕阅读器行为
- **组件状态**：标记为 Stable / Beta / Deprecated / Experimental

### 治理流程
- 新增组件的提案和评审流程
- 修改现有组件的影响评估流程
- 废弃组件的迁移计划和时间表
- 组件使用度量：哪些组件被广泛使用，哪些无人使用

### 版本管理
- 设计系统使用语义化版本（SemVer）
- Breaking Change 必须有迁移指南
- 变更日志记录每次修改的内容和原因
