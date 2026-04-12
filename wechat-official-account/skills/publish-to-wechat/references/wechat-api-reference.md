# 微信公众平台 API 参考

---

## 1. 获取 access_token

```
GET https://api.weixin.qq.com/cgi-bin/token
  ?grant_type=client_credential&appid=APPID&secret=APPSECRET
```

- 有效期 7200 秒（2 小时），每日上限 2000 次
- 建议缓存，过期前 5 分钟刷新；刷新后旧 token 5 分钟内仍可用

### 错误码速查

| errcode | 说明 | 解决方案 |
|---------|------|---------|
| 40001 | AppSecret 错误 | 重新确认 AppSecret |
| 40164 | IP 未加白名单 | 到后台 → 基本配置 → IP 白名单添加 |
| 45009 | API 调用次数超限 | 等待次日重置或优化调用频率 |

---

## 2. 草稿箱 API（draft/add）

```
POST https://api.weixin.qq.com/cgi-bin/draft/add?access_token=ACCESS_TOKEN
```

### 参数

| 参数 | 必填 | 说明 |
|------|------|------|
| title | 是 | 标题，最多 64 字 |
| author | 否 | 作者，最多 8 字 |
| digest | 否 | 摘要，最多 120 字（不填自动抓取前 64 字） |
| content | 是 | HTML 正文，上限约 2 万字 |
| thumb_media_id | 是 | 封面图永久素材 media_id |
| need_open_comment | 否 | 0=关闭评论 1=打开 |
| only_fans_can_comment | 否 | 仅粉丝可评论 |

多图文草稿：articles 数组支持最多 8 篇。

---

## 3. 素材上传 API

### 永久素材（封面图）

```
POST https://api.weixin.qq.com/cgi-bin/material/add_material
  ?access_token=ACCESS_TOKEN&type=image
```

### 图文内容图片

```
POST https://api.weixin.qq.com/cgi-bin/media/uploadimg
  ?access_token=ACCESS_TOKEN
```

返回永久图片 URL（mmbiz.qpic.cn 域名），可直接用于 `<img src>`。

### 素材限制

| 类型 | 格式 | 大小限制 |
|------|------|---------|
| 图片 | PNG/JPEG/JPG/GIF | 10MB |
| 封面图 | PNG/JPEG/JPG | 2MB，推荐 900x383 或 500x500 |
| 永久素材总数 | — | 图片 5000 个 |
