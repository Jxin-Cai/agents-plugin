# 组件设计原则

---

## 1. Atomic Design 层级体系

| 层级 | 职责 | 可含业务逻辑 | 违规信号 |
|------|------|-------------|---------|
| Atoms | 最小 UI 单元（按钮、输入框、图标） | 否 | Button 内含 API 调用 |
| Molecules | Atoms 组合（搜索栏、表单字段） | 简单交互 | FormField 管理表单提交 |
| Organisms | 功能区块（导航栏、卡片列表） | 是 | Header 包含整页状态管理 |
| Templates | 页面布局骨架 | 否 | 混入了具体数据 |
| Pages | 注入真实数据 + 路由 | 是 | — |

**核心检查**：组件是否在正确层级？是否存在层级越界？

---

## 2. 单一职责原则

| 拆分信号 | 动作 |
|---------|------|
| 单组件 > 200 行 | 审视是否可拆分 |
| 大段 if/else 渲染不同 UI | 拆为变体组件 |
| 同时处理数据获取和 UI 渲染 | 抽取 Custom Hook |
| Props > 10 个 | 组合模式或拆分 |
| 多个独立 useEffect | 各自抽取为 Hook |

复杂 UI（Select / Tabs / Accordion）推荐复合组件模式（`<Select><Select.Trigger/>...`），避免单组件 Props 膨胀。

---

## 3. Props 接口设计

**命名规范**：布尔值 `is-`/`has-`/`can-` 前缀 | 回调 `on-` + 动词 | 枚举用 union type

**设计原则**：
- 最小必要接口，80% 场景无需额外 Props
- 全部 TypeScript 类型定义，禁止 `any`
- Props 透传 > 2 层 → Context / Provide-Inject / 组合模式

| 反模式 | 修复 |
|--------|------|
| `options: any[]` | 具体类型定义 |
| > 5 个布尔 Props | variant 枚举替代 |
| style/className 直接透传 | 限制可自定义范围 |

---

## 4. 状态管理分层

| 状态类型 | 存放位置 | 示例 |
|---------|---------|------|
| 局部 UI | useState / ref | 下拉展开、输入聚焦 |
| 跨组件共享 | Context / Store | 主题、用户信息 |
| 服务端数据 | React Query / SWR | API 数据、缓存 |
| URL 状态 | Router / SearchParams | 分页、筛选 |
| 表单状态 | 表单库 | 表单值、校验 |

**审查规则**：就近管理 / 派生值用 useMemo·computed 不冗余存储 / 禁止 useEffect 同步两个 state / API 数据用缓存库

---

## 5. 可访问性基础标准

| 维度 | 要求 |
|------|------|
| 语义 HTML | 交互用原生标签（`<button>` 非 `<div onClick>`），列表用 `<ul/ol>`，结构用 `<header/main/nav>` |
| ARIA | 自定义组件有 `role`，图标按钮有 `aria-label`，动态区域用 `aria-live` |
| 键盘 | Tab 聚焦所有交互元素，焦点顺序=视觉顺序，模态框焦点陷阱，Esc 关闭弹窗 |
| 对比度 | 文本/背景 >= 4.5:1（普通）或 3:1（大文本），不单独依赖颜色传达信息 |

---

## 6. 代码质量信号

| 正向 | 负向 |
|------|------|
| JSDoc / TSDoc 注释 | 大量 `@ts-ignore` / `as any` |
| 单元测试或 Storybook | 注释掉的代码未清理 |
| CSS Modules / Tailwind 避免污染 | 魔法数字无常量命名 |
| Error Boundary 保护关键区域 | console.log 残留 / 内联样式 > 3 属性 |
