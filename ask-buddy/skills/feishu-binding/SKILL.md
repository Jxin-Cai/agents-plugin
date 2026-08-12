---
name: feishu-binding
description: 用户要求绑定、连接或扫码登录飞书，或飞书日历/任务/邮箱读取缺少配置时使用。采用只读权限、项目级元数据和分步二维码流程。
---

## 安全绑定流程

1. 调用 `feishu_binding_status` 查看当前项目状态，不输出或复述 token、设备码或 app secret。
2. 调用 `feishu_binding_preflight`。若返回 `MISSING_CONFIG`，按 guidance 执行 `lark-cli config init --new`，不要要求用户把 secret 粘贴到对话或项目文件。
3. 调用 `feishu_binding_start` 获取二维码图片；只把图片展示给用户，等待用户在飞书移动端确认。
4. 用户确认后调用 `feishu_binding_complete`（带返回的 `binding_id`）。完成后再次调用 status 验证。

桥接只申请日历、任务、忙闲和邮箱读取权限。`.ask-buddy/.env` 只保存当前项目的状态、绑定 ID、时间和 scope 元数据，权限为 600；设备码和 token 由进程内存或官方 CLI/keychain 管理，不得持久化。二维码地址如返回，仅限本次响应使用，不写入文件。

绑定流程是唯一允许的外部授权交互；日常简报仍然只能调用只读工具，不创建、修改或删除飞书数据。
