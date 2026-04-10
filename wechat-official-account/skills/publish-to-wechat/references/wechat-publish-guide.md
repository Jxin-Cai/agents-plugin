# 微信公众平台发布技术指南

本文档提供微信公众号文章发布的完整技术指南，包括 API 接入、内容格式规范、Markdown 转换、浏览器自动化和常见问题排查。

---

## 1. 微信公众平台 API 接入指南

### 获取 AppID 和 AppSecret

1. 访问 https://mp.weixin.qq.com 并登录
2. 进入 **设置与开发** → **基本配置**
3. 开发者ID(AppID) 直接显示
4. 开发者密码(AppSecret) 需点击"重置"生成
5. **IP 白名单**：必须将调用 API 的服务器 IP 添加到白名单

### access_token 刷新机制

#### 获取 access_token

```
GET https://api.weixin.qq.com/cgi-bin/token
  ?grant_type=client_credential
  &appid=APPID
  &secret=APPSECRET
```

成功返回：
```json
{
  "access_token": "ACCESS_TOKEN",
  "expires_in": 7200
}
```

#### 刷新策略

- access_token 有效期 7200 秒（2 小时）
- 每日调用上限 2000 次
- 建议：获取后缓存，过期前 5 分钟刷新
- 刷新后旧 token 在 5 分钟内仍可用（平滑过渡）

#### 错误码速查

| errcode | 说明 | 解决方案 |
|---------|------|---------|
| 40001 | AppSecret 错误或不属于该公众号 | 重新确认 AppSecret |
| 40002 | grant_type 不正确 | 使用 client_credential |
| 40164 | IP 未加入白名单 | 到后台添加调用方 IP |
| 41004 | AppSecret 缺失 | 检查请求参数 |
| 45009 | API 调用次数超限 | 等待次日重置或优化调用频率 |
| 50004 | 禁止使用 token 接口 | 确认公众号权限 |

---

## 2. 草稿箱 API（draft/add）详解

### 创建草稿

```
POST https://api.weixin.qq.com/cgi-bin/draft/add?access_token=ACCESS_TOKEN
Content-Type: application/json

{
  "articles": [
    {
      "title": "文章标题",
      "author": "作者",
      "digest": "摘要（选填，不填自动抓取正文前64字）",
      "content": "<p>HTML正文内容</p>",
      "content_source_url": "阅读原文链接（选填）",
      "thumb_media_id": "封面图的media_id（必填）",
      "need_open_comment": 0,
      "only_fans_can_comment": 0,
      "pic_crop_235_1": "0_0_1_0.5",
      "pic_crop_1_1": "0_0.1_1_0.9"
    }
  ]
}
```

### 参数详解

| 参数 | 必填 | 类型 | 说明 |
|------|------|------|------|
| title | 是 | string | 标题，最多 64 字 |
| author | 否 | string | 作者，最多 8 字 |
| digest | 否 | string | 摘要，最多 120 字 |
| content | 是 | string | HTML 正文，上限约 2 万字（带格式） |
| content_source_url | 否 | string | 阅读原文链接 |
| thumb_media_id | 是 | string | 封面图的永久素材 media_id |
| need_open_comment | 否 | int | 是否打开评论，0=关闭 1=打开 |
| only_fans_can_comment | 否 | int | 是否仅粉丝可评论 |
| pic_crop_235_1 | 否 | string | 封面裁剪坐标 2.35:1 |
| pic_crop_1_1 | 否 | string | 封面裁剪坐标 1:1 |

### 返回值

成功：
```json
{"media_id": "MEDIA_ID"}
```

### 多图文草稿

articles 数组支持多篇文章，最多 8 篇：
```json
{
  "articles": [
    {"title": "头条", ...},
    {"title": "次条", ...},
    {"title": "第三条", ...}
  ]
}
```

---

## 3. 素材上传 API

### 上传临时素材（3 天有效）

```
POST https://api.weixin.qq.com/cgi-bin/media/upload
  ?access_token=ACCESS_TOKEN
  &type=image

Content-Type: multipart/form-data
media: @文件
```

### 上传永久素材（用于封面图）

```
POST https://api.weixin.qq.com/cgi-bin/material/add_material
  ?access_token=ACCESS_TOKEN
  &type=image

Content-Type: multipart/form-data
media: @文件
```

返回：
```json
{
  "media_id": "MEDIA_ID",
  "url": "https://mmbiz.qpic.cn/..."
}
```

### 上传图文内容中的图片

```
POST https://api.weixin.qq.com/cgi-bin/media/uploadimg
  ?access_token=ACCESS_TOKEN

Content-Type: multipart/form-data
media: @文件
```

返回：
```json
{
  "url": "https://mmbiz.qpic.cn/mmbiz_jpg/..."
}
```

**注意：** 此接口返回的 URL 可直接用于图文内容中的 `<img src="...">`。

### 素材限制

| 类型 | 格式 | 大小限制 |
|------|------|---------|
| 图片 | PNG/JPEG/JPG/GIF | 10MB |
| 封面图 | PNG/JPEG/JPG | 2MB，推荐 900x383 或 500x500 |
| 内容图 | PNG/JPEG/JPG/GIF | 10MB |
| 永久素材总数 | — | 图片 5000 个，其他各 1000 个 |

---

## 4. 内容格式限制

### 微信 HTML 白名单标签

微信编辑器允许的 HTML 标签（非白名单标签会被过滤）：

**文本标签：**
`<p>`, `<span>`, `<strong>`, `<b>`, `<em>`, `<i>`, `<u>`, `<s>`, `<del>`, `<sub>`, `<sup>`, `<br>`

**结构标签：**
`<div>`, `<section>`, `<article>`, `<h1>`-`<h6>`, `<blockquote>`, `<pre>`, `<code>`, `<hr>`

**列表标签：**
`<ul>`, `<ol>`, `<li>`

**表格标签：**
`<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`

**媒体标签：**
`<img>`, `<video>`（仅限微信视频）

**允许的样式属性（通过 style 内联）：**
`color`, `font-size`, `font-weight`, `font-style`, `text-decoration`, `text-align`, `line-height`, `letter-spacing`, `background-color`, `background`, `border`, `border-radius`, `padding`, `margin`, `width`, `max-width`, `height`, `display`, `overflow`, `white-space`, `box-sizing`, `vertical-align`

### 不允许的内容

- `<script>` 标签（所有 JavaScript）
- `<link>` 标签（外部 CSS）
- `<style>` 标签（内部 CSS，部分情况可用但不推荐）
- `<iframe>` 标签（除微信视频外）
- `<a href="...">` 外部链接（未认证公众号完全不可用，已认证公众号仅限白名单域名）
- `<form>` 表单元素

### 外链限制详解

| 公众号类型 | 外链能力 |
|-----------|---------|
| 未认证订阅号 | 不支持任何外链 |
| 已认证订阅号 | 仅支持"阅读原文"一个外链入口 |
| 已认证服务号 | 支持公众号文章互链，"阅读原文"外链 |
| 微信认证+开通相关能力 | 支持设置最多 200 个安全域名的外链 |

**通用处理策略：** 所有外部链接一律转换为底部引用格式，确保在所有公众号类型下都能正常展示。

---

## 5. Markdown → 微信 HTML 转换规则

### 完整转换映射

#### 标题

```markdown
# 一级标题
## 二级标题
### 三级标题
```

→

```html
<h2 style="font-size:20px;font-weight:bold;color:{主色调};margin:25px 0 15px;padding-bottom:8px;border-bottom:2px solid {主色调};">一级标题</h2>
<h3 style="font-size:18px;font-weight:bold;color:{主色调};margin:20px 0 10px;">二级标题</h3>
<h3 style="font-size:16px;font-weight:bold;color:#333;margin:15px 0 8px;">三级标题</h3>
```

注意：微信中 `<h1>` 过大，Markdown 的 `#` 映射到 `<h2>`，`##` 映射到 `<h3>`。

#### 段落

```markdown
这是一个段落。

这是另一个段落。
```

→

```html
<p style="font-size:{字号};line-height:{行距};color:{正文色};margin:10px 0;letter-spacing:1px;">这是一个段落。</p>
<p style="font-size:{字号};line-height:{行距};color:{正文色};margin:10px 0;letter-spacing:1px;">这是另一个段落。</p>
```

#### 引用块

```markdown
> 这是一段引用
```

→

```html
<blockquote style="border-left:3px solid {主色调};padding:10px 15px;background:#f7f7f7;margin:15px 0;color:#666;font-size:15px;line-height:1.75;">
  <p style="margin:0;">这是一段引用</p>
</blockquote>
```

#### 列表

```markdown
- 项目一
- 项目二
  - 子项目
```

→

```html
<ul style="margin:10px 0;padding-left:20px;">
  <li style="font-size:{字号};line-height:2;color:{正文色};">项目一</li>
  <li style="font-size:{字号};line-height:2;color:{正文色};">项目二
    <ul style="margin:5px 0;padding-left:20px;">
      <li style="font-size:{字号};line-height:2;color:{正文色};">子项目</li>
    </ul>
  </li>
</ul>
```

#### 代码

行内代码：
```markdown
使用 `console.log()` 输出
```

→

```html
使用 <code style="background:#f5f5f5;padding:2px 6px;border-radius:3px;font-size:14px;color:#c7254e;font-family:Menlo,Monaco,Consolas,monospace;">console.log()</code> 输出
```

代码块：
````markdown
```javascript
function hello() {
  console.log("hello");
}
```
````

→

```html
<section style="background:#f8f8f8;border-radius:5px;padding:15px;margin:15px 0;overflow-x:auto;">
  <pre style="margin:0;font-size:14px;line-height:1.6;font-family:Menlo,Monaco,Consolas,monospace;white-space:pre-wrap;word-wrap:break-word;"><code>function hello() {
  console.log("hello");
}</code></pre>
</section>
```

#### 外部链接

```markdown
参考 [Google](https://google.com) 的做法
```

→

```html
<p>参考 Google<sup style="color:{主色调};font-size:12px;">[1]</sup> 的做法</p>

<!-- 文末追加 -->
<section style="margin-top:30px;padding-top:15px;border-top:1px solid #e5e5e5;">
  <p style="font-size:13px;color:#999;margin:5px 0;">引用链接：</p>
  <p style="font-size:12px;color:#999;margin:3px 0;word-break:break-all;">[1] Google: https://google.com</p>
</section>
```

#### 图片

```markdown
![图片描述](https://example.com/image.jpg)
```

→

```html
<figure style="text-align:center;margin:15px 0;">
  <img src="https://mmbiz.qpic.cn/上传后的URL" style="max-width:100%;border-radius:4px;" alt="图片描述">
  <figcaption style="font-size:12px;color:#999;margin-top:5px;">图片描述</figcaption>
</figure>
```

**注意：** 图片 URL 必须是微信素材库的 URL（mmbiz.qpic.cn 域名），外部 URL 可能无法加载。

#### 表格

```markdown
| 列1 | 列2 | 列3 |
|-----|-----|-----|
| 值1 | 值2 | 值3 |
```

→

```html
<table style="width:100%;border-collapse:collapse;margin:15px 0;font-size:14px;">
  <thead>
    <tr style="background:{主色调};color:#fff;">
      <th style="padding:8px 12px;text-align:left;border:1px solid #e5e5e5;">列1</th>
      <th style="padding:8px 12px;text-align:left;border:1px solid #e5e5e5;">列2</th>
      <th style="padding:8px 12px;text-align:left;border:1px solid #e5e5e5;">列3</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td style="padding:8px 12px;border:1px solid #e5e5e5;">值1</td>
      <td style="padding:8px 12px;border:1px solid #e5e5e5;">值2</td>
      <td style="padding:8px 12px;border:1px solid #e5e5e5;">值3</td>
    </tr>
  </tbody>
</table>
```

#### 分割线

```markdown
---
```

→

```html
<hr style="border:none;border-top:1px solid #e5e5e5;margin:20px 0;">
```

---

## 6. 浏览器方式注意事项

### 登录态保持

- 微信公众平台的登录态基于 Cookie
- 首次使用需要扫码登录
- Cookie 有效期约 24 小时
- 建议：使用 Chrome 的 User Data Directory 保持登录态

### Playwright 操作要点

#### 进入编辑器

```javascript
// 方式1：直接导航到新建图文页面
await page.goto('https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit&action=edit&type=77');

// 方式2：通过界面操作
await page.click('text=内容管理');
await page.click('text=发表内容');
```

#### 设置编辑器内容

公众号后台使用富文本编辑器，需要通过 JavaScript 注入内容：

```javascript
// 获取编辑器实例并设置内容
await page.evaluate((html) => {
  const editor = document.querySelector('#ueditor_0');
  if (editor) {
    editor.contentWindow.document.body.innerHTML = html;
  }
}, convertedHtml);
```

#### 填写元数据

```javascript
// 标题
await page.fill('#title', '文章标题');

// 作者
await page.fill('#author', '作者名');

// 摘要
await page.fill('#digest', '文章摘要');
```

#### 保存草稿

```javascript
await page.click('#js_submit'); // 保存草稿按钮
await page.waitForSelector('.tips_global_success'); // 等待保存成功提示
```

### Cookie 管理

如果需要跨会话保持登录：

```javascript
// 保存 Cookie
const cookies = await context.cookies();
fs.writeFileSync('.wechat-oa/cookies.json', JSON.stringify(cookies));

// 恢复 Cookie
const cookies = JSON.parse(fs.readFileSync('.wechat-oa/cookies.json'));
await context.addCookies(cookies);
```

---

## 7. EXTEND.md 配置格式详解

### 完整配置模板

```markdown
# 微信公众号配置

## 账号信息
- 公众号名称：{名称}
- 公众号类型：订阅号 / 服务号
- 认证状态：已认证 / 未认证
- 公众号ID：{微信号}

## 发布偏好
- 默认主题：default
- 主色调：#1a73e8
- 正文色：#3f3f3f
- 背景色：#ffffff
- 默认作者：{作者名}
- 默认字号：16px
- 默认行距：1.75
- 启用评论：否
- 仅粉丝可评论：是
- 启用赞赏：否

## 内容风格
- 语气：专业
- 目标读者：{描述}
- 内容定位：{描述}
- 行文风格：{简洁/详细/口语化/书面化}

## 发布设置
- 默认发布方式：api
- 阅读原文链接模板：{URL模板}
```

### 多账号管理

在 EXTEND.md 中支持多账号配置：

```markdown
## 账号列表

### 主号：{公众号名称A}
- AppID 环境变量：WECHAT_APP_ID_A
- 默认主题：default
- 默认作者：{作者A}

### 副号：{公众号名称B}
- AppID 环境变量：WECHAT_APP_ID_B
- 默认主题：elegant
- 默认作者：{作者B}
```

对应的 `.env` 文件：
```
WECHAT_APP_ID_A=wx_a_appid
WECHAT_APP_SECRET_A=wx_a_secret
WECHAT_APP_ID_B=wx_b_appid
WECHAT_APP_SECRET_B=wx_b_secret
```

---

## 8. 多账号管理方案

### 场景

一个运营者管理多个公众号，需要：
- 不同号使用不同的 API 凭证
- 不同号有不同的样式偏好
- 统一的内容管理工作流

### 实现方案

1. **凭证隔离**：每个账号独立的环境变量前缀
2. **配置继承**：全局默认配置 + 账号级覆盖
3. **发布时选择**：在 Step 2 增加账号选择环节

### 操作流程

1. 列出已配置的所有账号
2. 使用 `AskUserQuestion` 让用户选择目标账号
3. 加载该账号的凭证和样式配置
4. 后续流程使用该账号的配置

---

## 9. 常见问题排查

### API 相关

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| access_token 获取失败 | IP 未加白名单 | 到后台 → 基本配置 → IP 白名单添加 |
| 草稿创建失败 45008 | 内容超过字数限制 | 拆分为多篇文章 |
| 草稿创建失败 45005 | 内容包含外链 | 检查 HTML 中是否有 `<a>` 标签 |
| 图片上传失败 | 格式或大小不符 | 转换为 JPG，压缩到 10MB 以内 |
| 封面图上传失败 | 超过 2MB | 压缩图片 |
| API 调用次数超限 | 每日上限 2000 次 | 缓存 access_token，减少重复调用 |

### 内容格式相关

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 样式丢失 | 使用了外部 CSS | 改用内联 style |
| 图片不显示 | 使用了外部图片 URL | 上传到微信素材库 |
| 链接不可点击 | 外链限制 | 转为底部引用格式 |
| 代码块样式异常 | 微信不支持语法高亮 | 使用纯文本样式的代码块 |
| 表格显示异常 | 列数过多，手机端过窄 | 3 列以上改用列表格式 |

### 浏览器方式相关

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 无法登录 | Cookie 过期 | 重新扫码登录 |
| 编辑器内容为空 | 注入方式不对 | 检查编辑器 DOM 结构 |
| 保存失败 | 必填字段未填 | 检查标题和封面图 |
| 页面加载超时 | 网络问题 | 增加等待时间 |
