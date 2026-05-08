#!/bin/bash
# Stop hook: 每轮结束后轻量检查状态一致性
# 仅在 .e2e-tests 目录存在时运行，输出简洁

[ -d ".e2e-tests" ] || exit 0

ISSUES=""

# 检查 1: registry index.yaml 存在但域文件缺失
if [ -f ".e2e-tests/shared/registry/index.yaml" ]; then
  # 简单检查：index 引用的域文件是否存在
  for DOMAIN_FILE in $(grep -oE '[A-Za-z0-9_]+\.yaml' .e2e-tests/shared/registry/index.yaml 2>/dev/null | sort -u); do
    if [ "$DOMAIN_FILE" != "index.yaml" ] && [ ! -f ".e2e-tests/shared/registry/$DOMAIN_FILE" ]; then
      ISSUES="${ISSUES}\n⚠️ registry 引用了 ${DOMAIN_FILE} 但文件不存在"
    fi
  done
fi

# 检查 2: 活跃 run 的 index.md status=active 但超过 7 天未更新
for INDEX_FILE in $(find .e2e-tests/scenarios -path "*/runs/*/index.md" 2>/dev/null); do
  STATUS=$(sed -n 's/^status: *//p' "$INDEX_FILE" 2>/dev/null | head -1)
  if [ "$STATUS" = "active" ]; then
    # 检查文件修改时间是否超过 7 天
    if [ "$(find "$INDEX_FILE" -mtime +7 2>/dev/null)" ]; then
      RUN_PATH=$(echo "$INDEX_FILE" | sed 's|/index.md||')
      ISSUES="${ISSUES}\n⚠️ 任务 ${RUN_PATH} 状态为 active 但已 7+ 天未更新"
    fi
  fi
done

# 检查 3: knowledge-index.md 超过容量阈值
if [ -f ".e2e-tests/shared/knowledge-index.md" ]; then
  LINES=$(wc -l < .e2e-tests/shared/knowledge-index.md | tr -d ' ')
  if [ "$LINES" -gt 200 ]; then
    ISSUES="${ISSUES}\n⚠️ knowledge-index.md 超过 200 行 (${LINES} 行)，需要截断"
  fi
fi

# 检查 4: 测试产物泄漏到 .e2e-tests/ 以外
# 检测项目根目录下是否有 test-report.md 或 task/ 目录等误放产物
LEAKED=""
if [ -f "test-report.md" ]; then
  LEAKED="${LEAKED}\n  - test-report.md（应在 .e2e-tests/scenarios/*/runs/*/reports/ 下）"
fi
if [ -d "task" ] && ls task/*.md task/*.png task/*.jpg 2>/dev/null | head -1 > /dev/null 2>&1; then
  LEAKED="${LEAKED}\n  - task/ 目录含测试产物（应在 .e2e-tests/ 下）"
fi
# 检查 test/ 目录（排除已有的 test-results-analyzer 插件目录）
if [ -d "test" ]; then
  LEAKED="${LEAKED}\n  - test/ 目录存在（测试产物应在 .e2e-tests/ 下，测试脚本应在 .e2e-tests/shared/automation/ 下）"
fi
# 检查根目录的 test-results/ 目录（Playwright CLI 默认输出目录）
if [ -d "test-results" ]; then
  LEAKED="${LEAKED}\n  - test-results/ 目录存在（Playwright 输出应重定向到 .e2e-tests/ 下，使用 --output 参数）"
fi
# 检查截图文件（扩大检测范围：所有 png/jpg/jpeg）
for F in $(find . -maxdepth 1 \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) 2>/dev/null | head -5); do
  LEAKED="${LEAKED}\n  - ${F}（截图应在 .e2e-tests/scenarios/*/runs/*/evidence/ 下）"
done
# 检查根目录的 page-*.png / page-*.jpeg（Playwright MCP 默认截图命名）
for F in $(find . -maxdepth 2 \( -name "page-*.png" -o -name "page-*.jpeg" \) ! -path "./.e2e-tests/*" 2>/dev/null | head -5); do
  LEAKED="${LEAKED}\n  - ${F}（Playwright MCP 默认截图泄漏，应指定 filename 到 .e2e-tests/ 路径）"
done
if [ -d "temp" ] && ls temp/test-* temp/report-* temp/evidence-* 2>/dev/null | head -1 > /dev/null 2>&1; then
  LEAKED="${LEAKED}\n  - temp/ 目录含测试产物（应在 .e2e-tests/ 下）"
fi
# 检查 .playwright-mcp/ 目录中的截图（Playwright MCP 有时也会输出到此）
if [ -d ".playwright-mcp" ]; then
  PW_SCREENSHOTS=$(find .playwright-mcp -name "page-*.png" -o -name "page-*.jpeg" -o -name "page-*.yml" 2>/dev/null | grep -v "\.log$" | head -5)
  if [ -n "$PW_SCREENSHOTS" ]; then
    LEAKED="${LEAKED}\n  - .playwright-mcp/ 含截图/快照文件（应在 .e2e-tests/scenarios/*/runs/*/evidence/ 下）"
  fi
fi
if [ -n "$LEAKED" ]; then
  ISSUES="${ISSUES}\n🚨 测试产物泄漏到 .e2e-tests/ 以外！以下文件应移入正确位置：${LEAKED}"
fi

# 检查 5: 有活跃 run 但缺少关键产物
for RUN_DIR in $(find .e2e-tests/scenarios -path "*/runs/*" -maxdepth 4 -mindepth 4 -type d 2>/dev/null); do
  if [ -f "${RUN_DIR}/index.md" ]; then
    RUN_STATUS=$(sed -n 's/^status: *//p' "${RUN_DIR}/index.md" 2>/dev/null | head -1)
    if [ "$RUN_STATUS" = "completed" ]; then
      # 已完成的 run 应该有报告
      REPORT_COUNT=$(find "${RUN_DIR}/reports" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$REPORT_COUNT" -eq 0 ]; then
        ISSUES="${ISSUES}\n⚠️ ${RUN_DIR} 状态为 completed 但缺少测试报告"
      fi
      # 已完成的 run 应该有证据
      EVIDENCE_COUNT=$(find "${RUN_DIR}/evidence" -type f 2>/dev/null | wc -l | tr -d ' ')
      if [ "$EVIDENCE_COUNT" -eq 0 ]; then
        ISSUES="${ISSUES}\n⚠️ ${RUN_DIR} 状态为 completed 但缺少证据文件"
      fi
    fi
  fi
done

# 检查 6: 环境配置为空（有活跃 run 但无环境文件）
ACTIVE_RUNS=$(find .e2e-tests/scenarios -path "*/runs/*/index.md" 2>/dev/null | wc -l | tr -d ' ')
ENV_COUNT=$(ls .e2e-tests/shared/env/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$ACTIVE_RUNS" -gt 0 ] && [ "$ENV_COUNT" -eq 0 ]; then
  ISSUES="${ISSUES}\n⚠️ 有 ${ACTIVE_RUNS} 个 run 记录但环境配置为空——环境数据未沉淀"
fi

# 发现问题时阻止本轮结束，让 Claude 继续修正
if [ -n "$ISSUES" ]; then
  MESSAGE="### QA 状态检查\n$(echo -e "$ISSUES")\n\n请先修正这些问题：所有 e2e 过程产物必须移动或重新写入 .e2e-tests/ 下正确位置，然后才能结束本轮。"
  MESSAGE="$MESSAGE" python3 - <<'PY'
import json
import os

print(json.dumps({
    "decision": "block",
    "reason": os.environ.get("MESSAGE", "E2E artifacts leaked outside .e2e-tests/.")
}, ensure_ascii=False))
PY
fi
