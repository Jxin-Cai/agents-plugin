# 缺陷复现 Playbook

仅在 workflow = `repro-loop` 时加载。

---

## 目标

稳定复现问题、拿到可信证据链、识别最小触发条件，并决定是否沉淀为回归资产。

---

## 核心输入

- 缺陷现象
- 触发条件/前置状态
- 影响角色与环境
- 已观察到的日志、报错、截图、接口异常
- 是否需要最终沉淀成脚本

---

## 推荐链路

1. `clarify-scope` 收敛最小复现条件与不可接受结果
2. `test-prep` 只做最小复现准备，不追求全量准备方案
3. `test-runner` 优先走 Path C（Playwright 探索）拿证据
4. 若复现稳定，再决定是否补 `test-scenario-gen` 或 `test-automation-builder`

---

## 重点澄清

- 这次的目标是"确认 bug 存在"还是"固化为回归"
- 哪个现象一出现就算复现成功
- 最小复现路径是什么
- 复现是否具有偶发性 / 时序敏感 / 环境敏感

---

## 交付物

所有产物写入对应路径：
- 任务装配 → `.e2e-tests/scenarios/{scenario}/runs/{run}/task.md`
- 准备方案 → `.e2e-tests/scenarios/{scenario}/runs/{run}/prep/TP-{NNN}-{slug}.md`
- 复现报告 → `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/TS-{NNN}-run-{RRR}.md`
- 证据文件 → `.e2e-tests/scenarios/{scenario}/runs/{run}/evidence/`
- **复现结论** → `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/repro-conclusion.md`（复现步骤 + 最小前置条件 + 证据链 + 稳定/偶发/未复现判定 + 是否建议沉淀）

## 落盘检查

流程结束前，用 Glob 逐项确认以下产物存在，缺失则补写：
- `.e2e-tests/scenarios/{scenario}/runs/{run}/task.md`
- `.e2e-tests/scenarios/{scenario}/runs/{run}/reports/repro-conclusion.md`
- `.e2e-tests/scenarios/{scenario}/runs/{run}/index.md`（已更新 status）

无复现结论文件不得结束流程。
