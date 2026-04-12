# 合规报告原则

## 1. VPAT/ACR 格式规范

VPAT（Voluntary Product Accessibility Template）由 ITI Council 维护，填写后称 ACR。当前版本 2.5。

| 版本 | 适用场景 | 覆盖标准 |
|------|---------|---------|
| WCAG Edition | 通用 Web 无障碍 | WCAG 2.x Level A/AA |
| 508 Edition | 美国联邦采购 | Revised Section 508 + WCAG 2.0 |
| EU Edition | 欧盟市场 | EN 301 549 + WCAG 2.1 |
| INT Edition | 国际综合版 | 以上合一 |

### ACR 标准结构

封面字段：VPAT Version / Product Name / Version / Report Date / Description / Contact / Evaluation Methods

正文：Table 1 (Level A 逐条) + Table 2 (Level AA 逐条)，每条含 Criteria / Conformance Level / Remarks and Explanations

## 2. 合规等级定义

| 状态 | 英文 | 含义 |
|------|------|------|
| 支持 | Supports | 完全满足，无已知缺陷 |
| 部分支持 | Partially Supports | 部分功能满足，存在已知问题 |
| 不支持 | Does Not Support | 未满足 |
| 不适用 | Not Applicable | 准则不适用（需说明理由） |
| 未评估 | Not Evaluated | 尚未审计（严禁猜测） |

**使用原则：** 诚实为先 / 证据驱动 / Remarks 必填（尤其部分支持和不支持） / 不适用需理由 / 未覆盖标未评估

## 3. 报告撰写规则

### 执行摘要

面向非技术读者（采购/法务/高管）：一句话总结合规状态 -> 3-5 个关键发现 -> 修复时间线估计 -> 避免术语 -> 标明审计范围

### 问题描述必含

WCAG 准则编号 + 具体位置(页面+元素) + 复现条件 + 用户影响(具体到残障类型) + 修复方案

### Remarks 撰写

好："首页轮播3张产品图缺alt(img.carousel-item)，SR用户无法获取产品信息。其余页面图片均有准确alt。"
差："部分图片缺少alt属性。"——缺位置、页面、影响。

## 4. 法律合规标准

| 标准 | 地区 | 适用范围 | 技术要求 |
|------|------|---------|---------|
| Section 508 | 美国 | 联邦采购ICT | WCAG 2.0 AA |
| ADA Title III | 美国 | 公共场所(含网站) | 参照WCAG 2.1 AA，诉讼持续增长 |
| EN 301 549 | 欧盟 | 公共采购ICT | WCAG 2.1 AA + 软硬件要求 |
| EAA | 欧盟 | 市场数字服务(2025.6生效) | 含APP/终端/电子文档 |
| AODA | 加拿大 | 安大略省组织 | -- |
| DDA | 澳大利亚 | 公共网站 | -- |
| JIS X 8341-3 | 日本 | 公商网站 | -- |
| GB/T 37668 | 中国 | 信息无障碍(推荐性) | -- |

## 5. 修复路线图编制

**优先级因素：** 严重性(阻断优先) > 影响范围(核心流程优先) > 用户量 > 修复成本(同级选简单的) > 法律风险

| 阶段 | 时间 | 内容 |
|------|------|------|
| 紧急修复 | 1-2周 | 所有阻断级 |
| 重点修复 | 2-4周 | 所有严重级 + 高影响中等级 |
| 持续改进 | 4-8周 | 剩余中等和轻微级 |
| 长期维护 | 持续 | CI/CD集成axe/Pa11y + 季度审计 + 团队培训 + 无障碍负责人 |
