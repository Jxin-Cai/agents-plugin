# 性能优化原则

本文档定义了性能检查阶段必须遵循的原则。检查时以这些原则作为评判标准。

---

## 1. Core Web Vitals 标准

### 三项核心指标（2024 标准）

| 指标 | 全称 | 测量内容 | 良好 | 需改进 | 差 |
|------|------|---------|------|--------|---|
| **LCP** | Largest Contentful Paint | 最大内容元素的渲染时间 | <= 2.5s | 2.5s - 4.0s | > 4.0s |
| **INP** | Interaction to Next Paint | 交互到下一帧绘制的延迟 | <= 200ms | 200ms - 500ms | > 500ms |
| **CLS** | Cumulative Layout Shift | 页面生命周期内的累积布局偏移 | <= 0.1 | 0.1 - 0.25 | > 0.25 |

### INP 取代 FID（2024.03）
- INP 比 FID 更全面：FID 只测量第一次交互的输入延迟，INP 测量所有交互中最差的一次的完整延迟（输入延迟 + 处理时间 + 呈现延迟）
- INP 的优化重点：减少长任务、避免主线程阻塞、优化事件处理函数

### 评估方法
- **实验室数据**：Lighthouse、Chrome DevTools Performance 面板
- **真实用户数据**：Chrome UX Report (CrUX)、web-vitals 库
- 代码审查时关注的是**代码模式**是否会导致指标劣化，而非实际测量值

---

## 2. 加载性能优化

### 关键渲染路径
浏览器渲染页面的关键路径：
```
HTML 解析 -> DOM 构建
                |
CSS 解析 -> CSSOM 构建 -> 渲染树 -> 布局 -> 绘制
                |
JS 执行 (可能阻塞)
```

**优化目标**：缩短关键路径长度，减少关键资源数量和大小。

### 资源加载优先级

| 优先级 | 资源类型 | 加载策略 |
|--------|---------|---------|
| 最高 | 首屏 HTML、关键 CSS | 内联或最先加载 |
| 高 | 首屏 JS、LCP 图片 | preload |
| 中 | 非关键 CSS、首屏下方图片 | 异步加载、lazy |
| 低 | 第三方脚本、分析、广告 | defer / async / 动态注入 |
| 最低 | 预取下一页资源 | prefetch / preconnect |

### JavaScript Bundle 优化

#### 代码分割策略
- **路由级分割**：每个路由一个 chunk，按需加载
- **组件级分割**：大组件（模态框、图表、富文本编辑器）动态 import
- **库级分割**：将大型第三方库独立为 vendor chunk

#### Bundle 大小警戒线
| 资源 | 建议大小（gzip） | 警戒线 |
|------|-----------------|--------|
| 首屏 JS | < 150kB | > 200kB 需关注 |
| 首屏 CSS | < 50kB | > 80kB 需关注 |
| 单个路由 chunk | < 100kB | > 150kB 需拆分 |
| 图片（首屏单张） | < 200kB | > 500kB 需优化 |

#### 常见大依赖替换
| 大依赖 | 大小 | 替代方案 | 大小 |
|--------|------|---------|------|
| moment.js | ~300kB | dayjs | ~7kB |
| lodash | ~70kB | lodash-es (按需) | 按需 |
| Chart.js | ~200kB | lightweight-charts | ~45kB |
| date-fns (全量) | ~75kB | date-fns (按需) | 按需 |

### 字体优化
- 使用 `font-display: swap`（或 `optional` 在要求更高的场景）
- 预加载关键字体：`<link rel="preload" as="font" crossorigin>`
- 子集化中文字体（中文字体通常 > 5MB，按需子集化可减至 < 500kB）
- 考虑使用系统字体栈减少字体下载

---

## 3. 渲染性能优化

### 重渲染控制（React / Vue）

#### React
- `React.memo`：对纯展示组件使用，避免 Props 未变时重渲染
- `useMemo`：缓存昂贵计算结果
- `useCallback`：稳定回调函数引用，防止子组件不必要的重渲染
- **注意**：不要过度使用 memo——对简单组件加 memo 可能比重渲染更慢

#### Vue
- `computed`：自动缓存派生值
- `v-once`：静态内容只渲染一次
- `shallowRef` / `shallowReactive`：对大型对象避免深层响应式

### 长列表虚拟化
当列表项超过 100 项时：
- 使用虚拟列表库（TanStack Virtual、react-window、vue-virtual-scroller）
- 只渲染可见区域 + 缓冲区的 DOM 节点
- 避免在列表项中使用复杂的子组件

### CSS 动画性能
| 属性 | GPU 加速 | 重排 | 重绘 | 推荐 |
|------|---------|------|------|------|
| transform | 是 | 否 | 否 | 强烈推荐 |
| opacity | 是 | 否 | 否 | 强烈推荐 |
| filter | 是 | 否 | 是 | 推荐 |
| width/height | 否 | 是 | 是 | 避免动画 |
| top/left | 否 | 是 | 是 | 用 transform 替代 |
| background-color | 否 | 否 | 是 | 可接受 |

### 防抖与节流
| 场景 | 策略 | 推荐延迟 |
|------|------|---------|
| 搜索输入 | debounce | 300-500ms |
| 窗口 resize | debounce | 150-250ms |
| 滚动事件 | throttle（rAF） | 16ms (60fps) |
| 按钮点击 | throttle | 300ms |
| 拖拽移动 | throttle（rAF） | 16ms (60fps) |

---

## 4. 视觉稳定性（CLS 防护）

### CLS 产生的常见原因
1. **无尺寸的图片/视频**：加载完成后撑开布局
2. **动态注入内容**：广告、弹窗、Toast 在视口内插入
3. **Web 字体闪烁**：FOIT（不可见文字闪烁）或 FOUT（无样式文字闪烁）
4. **异步组件**：加载完成后改变周围布局
5. **动态 className**：JS 加载后添加的 class 改变了布局

### CLS 防护策略
- **图片**：始终声明 `width` 和 `height`，或用 `aspect-ratio` CSS 属性
- **广告/嵌入**：预留固定尺寸的占位容器
- **字体**：使用 `font-display: optional`（零 CLS）或 `swap`（有 FOUT 但无 FOIT）
- **骨架屏**：异步内容加载前显示占位骨架
- **动态内容**：在视口下方插入，不在用户当前阅读区域插入

### CLS 评分计算
```
布局偏移分 = 影响比例 × 距离比例
CLS = 所有单次布局偏移分的总和（按会话窗口分组取最大值）
```
- 影响比例：不稳定元素影响的视口面积
- 距离比例：不稳定元素移动的最大距离 / 视口高度

---

## 5. 构建与部署优化

### 构建配置检查
| 检查项 | 期望 |
|--------|------|
| Tree-shaking | 启用，package.json 有 `sideEffects: false` |
| 代码压缩 | Terser / esbuild minify 启用 |
| CSS 压缩 | cssnano / lightningcss 启用 |
| Source Map | 生产环境不输出或使用 hidden-source-map |
| 模块格式 | ESM 优先（利于 tree-shaking） |

### 缓存策略
| 资源 | 缓存策略 |
|------|---------|
| HTML | no-cache 或短期缓存（5min） |
| CSS/JS（带 hash） | Cache-Control: max-age=31536000, immutable |
| 图片（带 hash） | Cache-Control: max-age=31536000, immutable |
| 字体 | Cache-Control: max-age=31536000, immutable |
| API 响应 | 按业务需求设定，通常 no-cache + ETag |

### 压缩传输
- Brotli（br）优先于 gzip（压缩率更高 20-30%）
- 确保服务器 / CDN 启用了压缩
- 静态资源可预压缩（构建时生成 .br / .gz 文件）

---

## 6. 性能预算

### 推荐性能预算
| 指标 | 预算 | 说明 |
|------|------|------|
| Time to Interactive | < 3.8s | 3G 网络下 |
| 首屏 JS 总量 | < 170kB (gzip) | 包含框架和业务代码 |
| 首屏 CSS 总量 | < 60kB (gzip) | 关键 CSS + 组件样式 |
| 首屏图片总量 | < 500kB | 所有首屏可见图片 |
| LCP | < 2.5s | 75th percentile |
| INP | < 200ms | 75th percentile |
| CLS | < 0.1 | 75th percentile |

### 预算执行
- 在 CI/CD 中集成 Lighthouse CI 或 bundlesize 检查
- Bundle 大小超过预算时构建失败
- 新增依赖前评估对 bundle 大小的影响（bundlephobia.com）
