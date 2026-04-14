# 发布就绪验证 Playbook

仅在 workflow = `release-gate` 时加载。

---

## 目标

给出一次发布/上线前验证的 go / no-go 判断，不追求全量设计模式产物，而是优先回答：
1. 本次发布影响了什么
2. 最小阻断验证集是什么
3. 当前是否达到可放行标准

---

## 核心输入

- 发布范围（模块、服务、前后端、配置变更）
- 发布环境
- 时间窗/冻结窗口
- 关键业务链路
- 阻断项定义（哪些失败会阻止发布）

---

## 推荐链路

1. 用 `clarify-scope` 明确发布目标、阻断项和最小验证集
2. 调用 `impact-analysis` 识别受影响测试范围
3. 若 `.e2e-tests/shared/env/{target_env}.yaml` 中定义了 `deploy_scripts.smoke_bootstrap`，提示用户运行以初始化环境
4. 调用 `run-suite` 执行 smoke / high-risk / changed 脚本
5. 对脚本未覆盖但发布风险高的场景，调用 `test-runner` 做定向验证
6. 输出发布结论：GO / NO-GO / CONDITIONAL GO

---

## 重点澄清

- 本次最担心什么出问题？
- 哪些结果属于阻断发布？
- 哪些链路必须在本轮覆盖？
- 是否允许用已有回归资产替代完整场景设计？

---

## 交付物

所有需求级产物写入对应路径：
- 任务装配 → `.e2e-tests/scenarios/{scenario}/runs/{run}/task.md`
- 定向验证报告 → `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/TS-{NNN}-run-{RRR}.md`
- **发布结论** → `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/release-conclusion.md`（GO/NO-GO/CONDITIONAL GO + 依据 + 未覆盖风险 + 限制说明）

全局可复用报告写入共享区：
- 影响分析报告 → `.e2e-tests/shared/reports/impact-{date}-{slug}.md`
- 回归报告 → `.e2e-tests/shared/reports/regression-{YYYY-MM-DD}-{HHmm}.md`

## 落盘检查

流程结束前，用 Glob 逐项确认以下产物存在，缺失则补写：
- `.e2e-tests/scenarios/{scenario}/runs/{run}/task.md`
- `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/release-conclusion.md`
- `.e2e-tests/scenarios/{scenario}/runs/{run}/index.md`（已更新 status）

无发布结论文件不得结束流程。
