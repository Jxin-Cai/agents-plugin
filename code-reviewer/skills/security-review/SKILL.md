---
name: security-review
description: 基于 OWASP Top 10 对目标代码进行安全漏洞扫描和风险评估
argument-hint: "<审查目标：PR 链接、文件路径或模块名>"
allowed-tools: ["Read", "Write", "Glob", "Grep", "Bash", "AskUserQuestion"]
---

# 安全审查

以白帽黑客视角审视代码，识别每一个可被利用的弱点。引导开发者理解安全风险，而非简单列出问题。

用户传入的参数：`$ARGUMENTS`

---

## Step 0: 前置条件

1. 确定工作目录：检查 `_code-review/` 下最近的日期目录，若无则创建 `_code-review/{日期}-{简写}/` 及子目录
2. 存在 `meta/review-state.md` 时 Read 并确认当前阶段为安全审查
3. Read `context/scope.md`（如存在）获取审查范围
4. 确定目标代码：`$ARGUMENTS` 含文件路径则 Read，含目录则 Glob 列出，含 PR 链接则提取变更文件

---

## Step 1: 识别技术栈与攻击面

Read `references/security-review-principles.md`

阅读目标代码，识别：

1. 技术栈：语言、框架、依赖库
2. 攻击面分类：外部输入点 / 数据存储点 / 外部调用点 / 认证授权点 / 配置和密钥

向用户展示攻击面概览。使用 `AskUserQuestion` 确认审查重点。

---

## Step 2: OWASP Top 10 逐项扫描

按 `references/security-review-principles.md` 中的 OWASP Top 10 框架逐项检查。

对每个类别记录：

| 字段 | 要求 |
|------|------|
| 问题描述 | 具体的安全问题 |
| 风险代码 | 文件路径 + 行号 |
| OWASP 类别 | A01-A10 |
| 风险等级 | Critical / High / Medium / Low |
| 攻击场景 | 攻击者如何利用 |
| 修复建议 | 具体方案 + 代码示例 |

不适用的类别标注 N/A 并说明原因。每检查完 3-4 个类别向用户展示中间结果。

---

## Step 3: 依赖安全检查

1. 定位依赖声明文件（package.json / pom.xml / requirements.txt / go.mod）
2. 检查锁文件（lock file）是否存在
3. 识别可能有已知漏洞的依赖（过旧版本、已弃用库）
4. 检查不必要的依赖（增加攻击面）

---

## Step 4: 生成安全报告

将结果汇总为结构化报告，保存到 `{工作目录}/security/security-report-{日期}.md`。

更新 `meta/review-state.md`（安全审查阶段 = done）。

报告保存后向用户展示绝对路径。

---

## Step 5: 门控确认

使用 `AskUserQuestion` 展示：

> 发现安全问题 [N] 个——Critical [a]、High [b]、Medium [c]、Low [d]。

选项：进入质量审计 / 深入某个安全问题 / 重新审查 / 结束审查

---

<IMPORTANT>
## 质量硬门控

- 安全问题一律标记为 Blocker，不得降级为 Suggestion
- 每个安全发现必须有具体代码引用（文件:行号），禁止无代码的泛泛描述
- 不阅读代码不得给出审查意见
- 不到用户确认，不进入下一步
- Critical 级安全问题必须在摘要中醒目标注
- 不确定风险等级时声明不确定，禁止猜测
</IMPORTANT>
