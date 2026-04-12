# 性能原则：渲染与视觉稳定性

---

## 1. 重渲染控制

### React
- `React.memo`：纯展示组件避免 Props 未变时重渲染
- `useMemo`：缓存昂贵计算结果
- `useCallback`：稳定回调函数引用，防止子组件重渲染
- 不要过度 memo——简单组件加 memo 可能比重渲染更慢

### Vue
- `computed`：自动缓存派生值
- `v-once`：静态内容只渲染一次
- `shallowRef` / `shallowReactive`：大型对象避免深层响应式

---

## 2. 长列表与动画

### 虚拟化
- 列表项 > 100 时必须虚拟化（TanStack Virtual / react-window / vue-virtual-scroller）
- 只渲染可见区域 + 缓冲区 DOM 节点，避免列表项内复杂子组件

### CSS 动画性能

| 属性 | GPU 加速 | 触发重排 | 推荐度 |
|------|---------|---------|--------|
| transform / opacity | 是 | 否 | 强烈推荐 |
| filter | 是 | 否 | 推荐 |
| width / height / top / left | 否 | 是 | 避免动画 |

---

## 3. 防抖与节流

| 场景 | 策略 | 推荐延迟 |
|------|------|---------|
| 搜索输入 | debounce | 300-500ms |
| 窗口 resize | debounce | 150-250ms |
| 滚动 / 拖拽 | throttle（rAF） | 16ms (60fps) |
| 按钮点击 | throttle | 300ms |

---

## 4. CLS 防护

### 常见原因
- 无尺寸图片/视频加载后撑开布局
- 动态注入内容（广告 / 弹窗 / Toast）在视口内插入
- Web 字体闪烁（FOIT / FOUT）
- 异步组件加载改变周围布局

### 防护策略

| 场景 | 策略 |
|------|------|
| 图片 | 声明 `width` / `height` 或 CSS `aspect-ratio` |
| 广告/嵌入 | 预留固定尺寸占位容器 |
| 字体 | `font-display: optional`（零 CLS）或 `swap`（有 FOUT） |
| 异步内容 | 骨架屏占位 |
| 动态内容 | 在视口下方插入，不在用户阅读区域插入 |

---

## 5. 构建配置检查

| 检查项 | 期望 |
|--------|------|
| Tree-shaking | 启用，`sideEffects: false` |
| 代码压缩 | Terser / esbuild minify |
| CSS 压缩 | cssnano / lightningcss |
| Source Map | 生产不输出或 hidden-source-map |
| 模块格式 | ESM 优先（利于 tree-shaking） |
| 压缩传输 | Brotli 优先于 gzip（高 20-30%） |
| 缓存策略 | 静态资源带 hash + 长期缓存，HTML 短期缓存 |
