# 响应式设计原则

本文档定义了响应式审计阶段必须遵循的原则。审计时以这些原则作为评判标准。

---

## 1. 移动优先（Mobile First）

### 核心理念
从最小的屏幕开始设计，然后逐步增强。移动优先不是"先做移动版"，而是"先定义核心体验，再逐步增加"。

### 实践规则
- 使用 `min-width` 媒体查询从小屏向大屏增强
- 禁止 `min-width` 和 `max-width` 混用——选定一个方向并坚持
- 基础样式（无媒体查询时）应该是移动端样式
- 先确保在 320px 宽度下能正常使用，再考虑大屏优化

### 反模式
- 在桌面端设计好后"缩小适配"——通常导致移动端体验糟糕
- `display: none` 在移动端隐藏大量内容——不是响应式，是偷懒
- `@media (max-width: 768px)` 作为唯一的移动端适配——遗漏了大量中间尺寸

---

## 2. 内容驱动断点

### 断点选择原则
断点应该在 **内容开始看起来不对的地方** 设置，而不是在特定设备宽度处。

### 推荐断点策略
虽然不应该死记设备宽度，但以下是常用的参考区间：

| 区间名称 | 范围 | 典型场景 |
|---------|------|---------|
| xs | 320px - 375px | 小屏手机（iPhone SE） |
| sm | 376px - 480px | 普通手机 |
| md | 481px - 768px | 平板竖屏 |
| lg | 769px - 1024px | 平板横屏 / 小笔记本 |
| xl | 1025px - 1440px | 普通桌面 |
| 2xl | 1441px+ | 大屏 / 外接显示器 |

### 断点治理
- 全项目统一断点变量（CSS Custom Properties 或预处理器变量）
- 所有断点在一个文件中集中定义
- 新增断点需要有正当理由（某个具体内容在此宽度下出问题）
- 避免超过 6 个断点——复杂度会指数增长

### Container Queries（2024+）
- 组件级响应式应优先使用 Container Queries
- `@container` 让组件根据自身容器宽度响应，而非视口宽度
- 适用场景：卡片组件在不同列数布局中的自适应、侧边栏展开/收起时的内容适配

---

## 3. 弹性布局系统

### 布局技术选择
| 场景 | 推荐技术 |
|------|---------|
| 一维排列（行/列） | Flexbox |
| 二维网格 | CSS Grid |
| 复杂页面骨架 | CSS Grid（宏布局）+ Flexbox（微布局） |
| 等宽列 | Grid `repeat(auto-fill, minmax(min, 1fr))` |
| 内容流布局 | Flexbox `flex-wrap: wrap` |

### 尺寸单位规范
| 属性 | 推荐单位 | 避免 |
|------|---------|------|
| 字体大小 | rem, clamp() | 固定 px |
| 间距/内边距 | rem, em | - |
| 容器宽度 | %, max-width + margin auto | 固定 px 宽度 |
| 行高 | 无单位数值（如 1.5） | px |
| 边框/阴影 | px | - |
| 媒体查询 | em（跨浏览器一致性最好） | px（大部分可以） |

### 弹性字体方案
推荐使用 `clamp()` 实现流体字体：
```css
/* 最小 16px，视口缩放，最大 24px */
font-size: clamp(1rem, 0.5rem + 2vw, 1.5rem);
```

### 溢出防护
- 所有容器设置 `overflow-x: hidden` 或 `overflow-wrap: break-word`
- 长 URL 和代码块使用 `word-break: break-all`
- 表格在小屏方案：1）横向滚动容器 2）将行转为卡片 3）隐藏次要列

---

## 4. 触控适配

### 触控目标尺寸
- **最小尺寸**：48x48px（WCAG 2.5.8 / Material Design 标准）
- **推荐尺寸**：44x44px（Apple HIG）到 48x48px
- **目标间距**：至少 8px，避免误触
- 即使视觉上元素较小，点击区域（padding / ::after 伪元素）也要达到最小尺寸

### Hover 与 Touch 分离
```css
/* 仅在支持 hover 的设备上应用 hover 效果 */
@media (hover: hover) and (pointer: fine) {
  .button:hover { background: var(--hover-bg); }
}

/* 触控设备上使用 active 状态替代 */
@media (hover: none) and (pointer: coarse) {
  .button:active { background: var(--active-bg); }
}
```

### 手势冲突
- 水平滑动区域不要与浏览器前进/后退手势冲突
- 下拉刷新区域不要与浏览器默认下拉冲突
- 轮播组件需要同时支持滑动和按钮操作

---

## 5. 图片与媒体响应式

### 响应式图片方案
```html
<!-- srcset + sizes: 浏览器根据视口选择最合适的图片 -->
<img
  srcset="image-400.webp 400w, image-800.webp 800w, image-1200.webp 1200w"
  sizes="(max-width: 600px) 100vw, (max-width: 1024px) 50vw, 33vw"
  src="image-800.webp"
  alt="描述"
  loading="lazy"
  decoding="async"
  width="800"
  height="600"
/>

<!-- picture: 按条件加载不同图片（艺术指导） -->
<picture>
  <source media="(max-width: 480px)" srcset="mobile.webp" />
  <source media="(max-width: 1024px)" srcset="tablet.webp" />
  <img src="desktop.webp" alt="描述" />
</picture>
```

### 图片格式优先级
1. AVIF（最佳压缩比，兼容性增长中）
2. WebP（广泛支持，优于 JPEG/PNG）
3. JPEG（照片降级方案）
4. PNG（需要透明度的降级方案）
5. SVG（图标、Logo、简单图形）

### CLS 防护
- 所有 `<img>` 标签必须声明 `width` 和 `height` 属性
- 或使用 CSS `aspect-ratio` 预留空间
- 动态加载的广告/嵌入内容需要预留占位区域

---

## 6. 响应式审计清单

### 快速检查项
| 检查项 | 方法 | 通过标准 |
|--------|------|---------|
| 无水平滚动 | 从 320px 到 2560px 逐步检查 | 任何宽度均无水平滚动条 |
| 文本可读性 | 检查 320px 下的字体大小 | body 字体 >= 16px |
| 触控目标 | 检查所有按钮和链接 | >= 48x48px |
| 图片自适应 | 缩放浏览器宽度 | 图片不溢出容器 |
| 导航可用 | 320px 下测试导航 | 所有导航项可达 |
| 表单可用 | 320px 下测试表单 | 输入框不溢出，键盘不遮挡 |
| 断点过渡 | 在每个断点附近缓慢缩放 | 过渡平滑，无跳变 |
