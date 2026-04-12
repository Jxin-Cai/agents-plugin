# 设计系统评审原则

---

## 1. 组件清单与一致性

### 完整性检查
- 所有页面 UI 元素是否在组件库中有对应？
- 变体覆盖：primary / secondary / danger / ghost 等
- 状态覆盖：default / hover / focus / active / disabled / loading / error
- 空状态（Empty State）是否被当作组件处理？

### 重复检测
- 功能重叠组件（如两种 Dialog/Modal）是否有设计意图？
- 评估合并或废弃可行性

### API 一致性
- Props 命名统一模式：如 `size="sm|md|lg"` 不混用 `small/medium/large`
- 颜色相关 Props 统一用 `variant`，不混用 `type/color/kind`
- 事件命名统一：`onChange` / `onClose`
- 插槽/子组件模式一致

---

## 2. Token 架构与使用规范

### 三层架构
```
全局 Token（Global）   -> 原始值：blue-500 = #3B82F6
语义 Token（Semantic） -> 用途映射：color-primary = blue-500
组件 Token（Component）-> 组件级覆盖：button-primary-bg = color-primary
```

### 使用规范
| 规则 | 说明 |
|------|------|
| 零硬编码 | 组件代码中不应出现原始颜色值、像素值、字体名 |
| 语义化命名 | Token 名称反映用途（`color-primary` 优于 `blue`） |
| 单一来源 | 每个设计决策只在一处定义 |
| 主题友好 | Token 架构支持深色模式/多主题切换 |

### 硬编码检测模式
- 颜色：`#[0-9a-fA-F]{3,8}`、`rgb(`、`rgba(`、`hsl(`
- 间距：CSS 中直接使用 `px`/`rem`/`em`（排除 Token 引用）
- 字体：`font-family:` 直接指定
- 阴影：`box-shadow:` 直接使用数值

---

## 3. 代码-设计一致性

| 维度 | 允许偏差 | 需要关注 | 严重偏差 |
|------|----------|----------|----------|
| 颜色 | Token 映射一致 | 1-2 处非标准色 | 大量硬编码 |
| 间距 | 遵循 4px/8px 网格 | 偶尔非网格值 | 无规律 |
| 字体 | 字号/行高/字重匹配 | 行高有微调 | 随意定义 |
| 圆角 | 统一使用 Token | 1-2 处自定义 | 无规律 |
| 阴影 | 使用定义好的层级 | 偶尔自定义 | 混乱 |
| 动画 | 统一时长和缓动曲线 | 个别组件自定义 | 不一致 |

发现偏差时追问：有意定制还是无意偏离？若定制应否回馈系统？偏离影响范围多大？

---

## 4. 命名规范

| 规则 | 说明 |
|------|------|
| 大小写 | PascalCase（React/Vue）或 kebab-case（WC/CSS） |
| 语义命名 | 反映职责而非样式（`AlertDialog` 优于 `RedPopup`） |
| 嵌套命名 | 复合组件一致（`Card` / `Card.Header` / `Card.Body`） |
| 禁止数字后缀 | `Button2` 是设计债务信号 |

推荐目录结构：`atoms/`（Button/Input）-> `molecules/`（FormField/Card）-> `organisms/`（Header/DataTable）-> `templates/`（PageLayout）-> `tokens/`

---

## 5. 文档与治理

### 组件文档标准
每个组件需包含：用途说明、2-3 种使用示例、Props/Slots/Events API 文档、Do's & Don'ts、无障碍说明（ARIA/键盘/屏幕阅读器）、状态标记（Stable/Beta/Deprecated/Experimental）

### 治理流程
- 新增组件：提案 -> 评审 -> 开发 -> 文档
- 修改组件：影响评估 -> 审批 -> 实施
- 废弃组件：迁移计划 + 时间表
- 版本管理：SemVer + Breaking Change 迁移指南 + 变更日志
