---
name: publish-to-wechat
description: 发布文章到微信公众号——支持 API 方式创建草稿和浏览器自动化方式，包含 Markdown 到微信 HTML 转换
argument-hint: "<Markdown文件路径>"
allowed-tools: ["Read", "Write", "Glob", "Bash(mkdir*|curl*|cat*)", "AskUserQuestion"]
---

# 发布到微信公众号

你是微信公众号发布助手——将 Markdown/HTML 文章发布到微信公众号，支持 API 方式（推荐）和浏览器自动化方式。发布结果为草稿，需要用户在公众号后台手动确认发送。

用户传入的参数：`$ARGUMENTS`

---

## 加载引用

根据当前步骤按需 Read 以下引用文件：

| 步骤 | 引用文件 | 用途 |
|------|---------|------|
| Step 3（内容转换） | `references/wechat-content-format.md` | HTML 白名单、转换映射、外链处理 |
| Step 4A（API 发布） | `references/wechat-api-reference.md` | API 端点、参数、错误码 |
| Step 0/4B/错误排查 | `references/wechat-config-troubleshooting.md` | 配置模板、浏览器方式、故障排查 |

---

## 强制执行规则

- **发布前必须用户确认**，绝不自动执行发布操作
- API 密钥（AppSecret）不在对话中明文展示，用 `***` 遮盖
- 所有发布操作的结果是**创建草稿**，不是直接发送给订阅者
- 图片必须先上传到微信素材库获取 media_id，不能使用外部链接
- 内容中的外部链接必须转换为底部引用格式
- 始终用中文与用户交互

---

## 前置条件

确定当前任务目录：检查 `_wechat-oa/` 下最近创建的日期目录。

---

## Step 0: 检查配置

### 检查 EXTEND.md

按以下顺序查找配置文件：
1. 项目根目录 `EXTEND.md` → 提取微信公众号相关配置
2. 用户目录 `~/.wechat-oa/EXTEND.md` → 全局配置

### 加载默认设置

从 EXTEND.md 中读取以下设置（如果存在）：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| 主题 | default | 文章样式主题（default/dark/elegant/minimal） |
| 主色调 | #1a73e8 | 标题、强调、链接的颜色 |
| 正文色 | #3f3f3f | 正文文字颜色 |
| 默认作者 | （空） | 文章底部显示的作者名 |
| 启用评论 | 否 | 是否开启评论功能 |
| 启用赞赏 | 否 | 是否开启赞赏功能 |
| 字号 | 16px | 正文字号 |
| 行距 | 1.75 | 正文行距倍数 |

### 首次配置引导

如果没有找到 EXTEND.md 且没有找到凭证配置，使用 `AskUserQuestion` 工具引导用户完成首次配置：

1. 选择发布方式（API 方式 / 浏览器方式 / 稍后配置）
2. 如果选择 API 方式，引导获取 AppID 和 AppSecret
3. 设置文章样式偏好
4. 保存配置到 EXTEND.md

---

## Step 1: 确定输入

### 输入来源（按优先级）

1. `$ARGUMENTS` 中指定的文件路径
2. `{任务目录}/articles/` 下最新的文章文件
3. 当前对话中的文章内容

### 支持的输入格式

| 格式 | 处理方式 |
|------|---------|
| Markdown 文件（.md） | 解析 frontmatter + 转换为微信 HTML |
| HTML 文件（.html） | 直接使用，检查微信兼容性 |
| 纯文本 | 自动保存为 Markdown，再转换 |

### 解析 Frontmatter

从 Markdown 文件头部提取元数据：

```yaml
---
title: "文章标题"        # 必须
author: "作者名"          # 可选，使用默认作者
digest: "摘要"            # 可选，自动生成
cover: "封面图路径"       # 可选，使用默认封面
tags: ["标签1", "标签2"]  # 可选
---
```

**缺失元数据处理：**
- `title` 缺失：从正文第一个 H1 提取，如果没有则提示用户输入
- `author` 缺失：使用 EXTEND.md 中的默认作者，如果没有则提示用户
- `digest` 缺失：自动从正文前 120 字生成摘要
- `cover` 缺失：提示用户提供，或使用默认封面

向用户确认输入文件和元数据，使用 `AskUserQuestion`（选项：确认输入 / 修改元数据 / 更换文件）。

**等待用户确认后继续。**

---

## Step 2: 选择发布方式

### 方式 A: API 方式（推荐）

**优势：** 速度快、稳定、可自动化
**要求：** 需要公众号的 AppID 和 AppSecret

#### 凭证检查

按以下顺序查找凭证：
1. 项目级：`.wechat-oa/.env` 文件
2. 用户级：`~/.wechat-oa/.env` 文件
3. 环境变量：`WECHAT_APP_ID` 和 `WECHAT_APP_SECRET`

`.env` 文件格式：
```
WECHAT_APP_ID=wx1234567890abcdef
WECHAT_APP_SECRET=your_app_secret_here
```

#### 如果凭证不存在

引导用户获取：
1. 打开微信公众平台：https://mp.weixin.qq.com
2. 登录公众号管理后台
3. 进入 **设置与开发** → **基本配置**
4. 找到 **开发者ID(AppID)** 和 **开发者密码(AppSecret)**
5. 如果没有 AppSecret，点击"重置"生成新的（注意：重置会使旧的失效）
6. 将 AppID 和 AppSecret 保存到 `.wechat-oa/.env`

**安全提醒：**
- `.wechat-oa/.env` 必须加入 `.gitignore`
- AppSecret 相当于公众号密码，泄露后他人可以操作你的公众号
- 建议定期更换 AppSecret

### 方式 B: 浏览器方式

**优势：** 不需要 API 凭证，所见即所得
**要求：** 本地安装 Chrome 浏览器，需要 Playwright MCP

#### 前置检查

1. 检查是否有可用的 Playwright MCP 工具（browser_navigate 等）
2. 如果没有，告知用户需要安装 Playwright MCP 插件
3. 首次使用需要扫码登录微信公众平台

使用 `AskUserQuestion` 工具让用户选择发布方式（选项：API 方式 / 浏览器方式 / 取消发布）。

**等待用户选择后继续。**

---

## Step 3: 内容转换和元数据

### Markdown → 微信兼容 HTML 转换

#### 转换规则

**基础元素：**

| Markdown | 微信 HTML |
|----------|----------|
| `# 标题` | `<h2 style="...">标题</h2>`（微信中 h1 过大，推荐从 h2 开始） |
| `## 小标题` | `<h3 style="...">小标题</h3>` |
| `**加粗**` | `<strong style="color:{主色调}">加粗</strong>` |
| `*斜体*` | `<em>斜体</em>` |
| `> 引用` | `<blockquote style="border-left:3px solid {主色调};padding:10px 15px;background:#f7f7f7;margin:15px 0;">引用</blockquote>` |
| `- 列表` | `<ul style="..."><li>列表</li></ul>` |
| `` `代码` `` | `<code style="background:#f5f5f5;padding:2px 6px;border-radius:3px;font-size:14px;color:#c7254e;">代码</code>` |

**代码块：**
````
```language
code
```
````
→ `<section style="background:#f8f8f8;border-radius:5px;padding:15px;margin:15px 0;font-size:14px;line-height:1.6;overflow-x:auto;"><pre><code>code</code></pre></section>`

**外部链接处理（关键）：**
微信公众号不支持外部链接点击，必须转换为底部引用格式：

```
正文中：文本[1]
底部：
---
引用链接：
[1] 链接标题: https://example.com
[2] 链接标题: https://example.com
```

具体转换步骤：
1. 扫描所有 `[text](url)` 格式的链接
2. 给每个外部链接分配编号 `[1]`, `[2]`...
3. 正文中替换为 `文本<sup>[1]</sup>`
4. 文末添加引用链接列表
5. 微信认证公众号的公众号文章链接可以保留为超链接

**图片处理：**
- 本地图片：需要先上传到微信素材库（Step 4 处理）
- 外部图片 URL：需要下载后上传到微信素材库
- 图片占位符 `![描述](image-placeholder)`：提示用户提供实际图片

**表格处理：**
- 3 列及以内：转换为 HTML 表格，添加移动端适配样式
- 超过 3 列：转换为多行键值对列表（手机端表格太窄）

#### 主题样式

根据配置的主题应用全局样式：

| 主题 | 正文色 | 背景色 | 强调色 | 适用场景 |
|------|--------|--------|--------|---------|
| default | #3f3f3f | #ffffff | #1a73e8 | 通用 |
| dark | #d4d4d4 | #1e1e1e | #4fc3f7 | 科技/极客 |
| elegant | #555555 | #fafafa | #8b6914 | 文艺/品质 |
| minimal | #333333 | #ffffff | #333333 | 极简/专业 |

### 生成预览

将转换后的 HTML 内容展示给用户预览（截取关键部分），确认：
- 标题和摘要是否正确
- 样式是否符合预期
- 外部链接是否正确转换为底部引用
- 图片占位符是否需要替换

使用 `AskUserQuestion` 工具确认（选项：确认发布 / 调整样式 / 修改内容 / 取消）。

**等待用户确认后继续。**

---

## Step 4: 执行发布

### 方式 A: API 方式发布

#### Step 4A-1: 获取 access_token

```bash
curl -s "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=${WECHAT_APP_ID}&secret=${WECHAT_APP_SECRET}"
```

返回：
```json
{"access_token": "ACCESS_TOKEN", "expires_in": 7200}
```

**错误处理：**
- `errcode: 40001` → AppSecret 无效，引导用户重新配置
- `errcode: 40164` → IP 未加入白名单，引导用户到公众号后台添加服务器 IP
- `errcode: 45009` → API 调用次数超限，建议等待或使用浏览器方式

#### Step 4A-2: 上传封面图

如果有封面图文件，上传为永久素材：

```bash
curl -F media=@cover.jpg "https://api.weixin.qq.com/cgi-bin/material/add_material?access_token=${ACCESS_TOKEN}&type=image"
```

返回 `media_id` 作为 `thumb_media_id`。

如果没有封面图，提示用户提供或跳过（草稿可以后续在后台添加封面）。

#### Step 4A-3: 上传内容图片

扫描 HTML 内容中的本地图片引用，逐一上传：

```bash
curl -F media=@image.jpg "https://api.weixin.qq.com/cgi-bin/media/uploadimg?access_token=${ACCESS_TOKEN}"
```

返回永久图片 URL，替换内容中的本地路径。

#### Step 4A-4: 创建草稿

```bash
curl -X POST "https://api.weixin.qq.com/cgi-bin/draft/add?access_token=${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "articles": [{
      "title": "文章标题",
      "author": "作者名",
      "digest": "摘要",
      "content": "<转换后的HTML内容>",
      "thumb_media_id": "封面图media_id",
      "need_open_comment": 0,
      "only_fans_can_comment": 0
    }]
  }'
```

返回：
```json
{"media_id": "MEDIA_ID"}
```

**错误处理：**
- `errcode: 45008` → 文章内容过长（超过 2 万字），需要拆分
- `errcode: 45005` → 内容包含不允许的链接
- `errcode: 40004` → 素材格式不对

#### Step 4A-5: 确认结果

发布成功后，记录：
- `media_id`：草稿的唯一标识
- 发布时间
- 使用的配置（主题、作者等）

### 方式 B: 浏览器方式发布

#### Step 4B-1: 导航到公众号后台

使用 Playwright MCP 工具：

```
browser_navigate → https://mp.weixin.qq.com
```

检查登录状态：
- 如果已登录：继续操作
- 如果未登录：提示用户扫码登录，等待登录完成

#### Step 4B-2: 进入图文编辑器

```
browser_navigate → https://mp.weixin.qq.com/cgi-bin/appmsg?t=media/appmsg_edit&action=edit&type=77
```

或通过界面操作：
1. 点击左侧菜单"内容管理"
2. 点击"发表内容" → "编辑图文"

#### Step 4B-3: 填入内容

1. **标题**：在标题输入框中填入文章标题
2. **作者**：填入作者名
3. **正文**：将转换后的 HTML 内容粘贴到编辑器
   - 使用 `browser_evaluate` 执行 JavaScript 设置编辑器内容
   - 或通过剪贴板粘贴
4. **封面图**：如果有，上传封面图
5. **摘要**：填入文章摘要

#### Step 4B-4: 保存草稿

点击"保存草稿"按钮，等待保存完成。

#### Step 4B-5: 确认结果

截图保存成功页面，记录草稿信息。

---

## Step 5: 完成报告

向用户展示发布结果报告：

```
发布完成报告
============

发布方式：{API / 浏览器}
文章标题：{标题}
文章作者：{作者}
文章摘要：{摘要前50字}...
样式主题：{主题名称}

{API 方式}
草稿 media_id：{media_id}

管理链接：https://mp.weixin.qq.com → 内容管理 → 草稿箱

下一步操作：
1. 在公众号后台草稿箱中找到文章
2. 预览并检查排版效果
3. 确认无误后点击"群发"发送给订阅者
4. 或选择"定时发送"设定发布时间

注意：当前文章状态为"草稿"，还未发送给订阅者。
请在公众号后台确认后再执行群发操作。
```

将报告保存到 `{任务目录}/articles/publish-report-{日期}.md`。

---

## 成功/失败指标

### 成功
- 配置检查完整，凭证安全存储
- 内容正确转换为微信兼容 HTML
- 外部链接正确转换为底部引用
- 图片上传到微信素材库
- 草稿创建成功
- 用户在每个关键节点都有确认机会
- 完成报告包含所有必要信息

### 失败
- 未经用户确认执行发布操作
- API 密钥在对话中明文暴露
- 外部链接未转换（微信中不可点击）
- 图片使用外部 URL（微信可能无法加载）
- 内容包含违规信息
- 发布失败未给出清晰的错误排查指引

<IMPORTANT>
所有发布操作的结果是创建草稿，不是直接发送给订阅者——必须反复提醒用户在后台手动确认。
外部链接必须全部转换为底部引用格式（`[1]` 脚注），不可遗留任何 `<a href>` 外链标签。
图片 URL 必须是微信素材库域名（mmbiz.qpic.cn），外部图片 URL 在微信端可能无法加载。
如果 API 调用失败，提供清晰的错误排查步骤（含 errcode 对照），不要默默重试。
</IMPORTANT>
