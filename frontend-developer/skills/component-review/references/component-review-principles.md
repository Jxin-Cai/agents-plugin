# 组件设计原则

本文档定义了组件架构审查阶段必须遵循的原则。审查时以这些原则作为评判标准。

---

## 1. Atomic Design 层级体系

UI 组件按粒度分为五层，每一层有明确的职责边界：

### Atoms（原子）
- 最小的 UI 单元：按钮、输入框、图标、标签、头像
- 不包含业务逻辑，纯展示
- Props 只有外观和行为参数（size、variant、disabled）
- 示例检查：一个 Button 组件是否包含了 API 调用？如果是，违反原子原则

### Molecules（分子）
- 由多个 Atoms 组合：搜索栏（Input + Button）、表单字段（Label + Input + ErrorMessage）
- 有简单的交互逻辑，但不直接调用 API
- 示例检查：一个 FormField 是否自己管理表单提交？如果是，职责越界

### Organisms（有机体）
- 功能完整的 UI 区块：导航栏、商品卡片列表、评论区
- 可以包含业务逻辑和 API 调用
- 示例检查：一个 Header 组件是否包含了整个页面的状态管理？如果是，需要拆分

### Templates（模板）
- 页面布局骨架，定义内容区域的位置
- 不包含具体数据，只有布局结构

### Pages（页面）
- 将真实数据注入 Templates
- 数据获取和路由逻辑在此层处理

**审查要点：** 检查组件是否在正确的层级，是否存在层级越界（如 Atom 层组件包含了 Organism 层的逻辑）。

---

## 2. 单一职责原则（SRP）

### 判定标准
- **行数警戒线**：单个组件超过 200 行代码需要审视是否可拆分
- **职责计数**：一个组件应该只有一个"变化的理由"
- **UI 与逻辑分离**：展示组件（Presentational）和容器组件（Container）应分离，或通过 Custom Hook 分离逻辑

### 拆分信号
- 组件内有大段 `if/else` 根据模式渲染不同 UI -> 拆成多个变体组件
- 组件同时处理数据获取和 UI 渲染 -> 抽取 Custom Hook
- 组件的 Props 超过 10 个 -> 考虑组合模式或拆分
- 组件内有多个独立的 useEffect -> 每个 effect 考虑抽取为 Hook

### 复合组件模式
对于复杂 UI（如 Select、Tabs、Accordion），推荐使用复合组件模式：
```
<Select>
  <Select.Trigger />
  <Select.Content>
    <Select.Item value="a">选项 A</Select.Item>
    <Select.Item value="b">选项 B</Select.Item>
  </Select.Content>
</Select>
```
而非将所有逻辑堆在单一组件的 Props 中。

---

## 3. Props 接口设计规范

### 命名规范
- 布尔值：`is-` / `has-` / `can-` / `should-` 前缀（`isDisabled`、`hasError`）
- 回调函数：`on-` + 动词（`onChange`、`onSubmit`、`onClose`）
- 渲染函数/插槽：`render-` 前缀（`renderHeader`）或 children/slots
- 枚举值：使用 union type 而非 string（`size: 'sm' | 'md' | 'lg'`）

### 设计原则
- **最小必要接口**：只暴露使用者需要的 Props，内部实现细节不泄露
- **合理默认值**：80% 的使用场景不需要传递额外 Props
- **类型安全**：所有 Props 有 TypeScript 类型定义，避免 `any`
- **Props 透传控制**：超过 2 层的 Props 透传需要考虑 Context / Provide-Inject / 组合模式

### 反模式检查
- **万能 Props**：`options: any[]` -> 应该有具体类型定义
- **布尔值爆炸**：超过 5 个布尔 Props -> 考虑用 variant 枚举替代
- **样式外泄**：`style` / `className` 直接透传到内部子元素 -> 限制可自定义的范围

---

## 4. 状态管理分层

### 状态分类
| 状态类型 | 存放位置 | 示例 |
|---------|---------|------|
| 局部 UI 状态 | 组件内 useState/ref | 下拉展开、输入聚焦 |
| 跨组件共享状态 | Context / Store | 主题、用户信息、购物车 |
| 服务端状态 | React Query / SWR / Pinia Query | API 数据、缓存 |
| URL 状态 | Router / SearchParams | 分页、筛选、排序 |
| 表单状态 | 表单库（React Hook Form / VeeValidate） | 表单值、校验 |

### 审查规则
- **就近原则**：状态尽量在最靠近使用它的组件中管理
- **派生状态不要冗余存储**：可计算的值用 useMemo / computed，不要额外存 state
- **避免状态同步**：如果两个 state 总是需要同步更新，合并为一个或提取为 reducer
- **服务端状态专用库**：API 数据不要放在普通 state 中，使用专用缓存库管理 loading / error / stale / refetch

### 反模式检查
- **全局状态滥用**：只有一个组件用到的数据放在了全局 store
- **状态冗余**：同一份数据在多处 state 中存了副本
- **useEffect 同步**：用 effect 在两个 state 之间做同步 -> 应该合并或用派生状态

---

## 5. 可访问性（A11y）基础标准

### 语义化 HTML
- 交互元素使用原生标签：`<button>`、`<a>`、`<input>`、`<select>`
- 禁止用 `<div>` + `onClick` 模拟按钮（除非添加了 `role="button"` + `tabIndex` + 键盘事件）
- 列表使用 `<ul>/<ol>/<li>`，表格使用 `<table>`
- 页面结构使用 `<header>`、`<main>`、`<nav>`、`<aside>`、`<footer>`

### ARIA 属性
- 自定义组件必须有适当的 `role` 属性
- 图标按钮必须有 `aria-label`
- 动态内容区域使用 `aria-live` 通知屏幕阅读器
- 展开/收起组件使用 `aria-expanded`

### 键盘导航
- 所有交互元素可通过 Tab 键聚焦
- 焦点顺序与视觉顺序一致
- 模态框需要焦点陷阱（Focus Trap）
- Esc 键可关闭弹窗/下拉

### 颜色与对比度
- 文本与背景的对比度至少 4.5:1（普通文本）或 3:1（大文本）
- 不单独依赖颜色传达信息（如错误状态要同时有图标和文字）

---

## 6. 代码质量信号

### 正向信号
- 组件有 JSDoc / TSDoc 注释说明用途
- 有对应的单元测试或 Storybook Stories
- 使用了 CSS Modules / Tailwind / styled-components 避免样式污染
- 错误边界（Error Boundary）保护关键 UI 区域

### 负向信号
- 大量 `// @ts-ignore` 或 `as any`
- 注释掉的代码块未清理
- 魔法数字（硬编码的数值没有常量命名）
- Console.log 残留在生产代码中
- 内联样式超过 3 个属性
