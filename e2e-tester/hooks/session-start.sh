#!/bin/bash
# SessionStart hook for e2e-tester plugin
# 1. 创建顶层工作目录（shared/ 公共区 + scenarios/ 剧本区）
# 2. 确保 knowledge-index.md 存在
# 3. 展示 QA 工作台状态 + 知识摘要

# ── 公共可复用资源区 ──
mkdir -p .e2e-tests/shared/env
mkdir -p .e2e-tests/shared/automation/auth
mkdir -p .e2e-tests/shared/datasets
mkdir -p .e2e-tests/shared/mocks
mkdir -p .e2e-tests/shared/helpers
mkdir -p .e2e-tests/shared/registry
mkdir -p .e2e-tests/shared/reports

# ── 测试剧本区 ──
mkdir -p .e2e-tests/scenarios

# ── Helper 脚本部署 ──
if [ -d ".e2e-tests/shared/helpers" ]; then
  PLUGIN_HELPERS="${CLAUDE_PLUGIN_ROOT}/shared-helpers"
  if [ -d "$PLUGIN_HELPERS" ]; then
    for helper in "$PLUGIN_HELPERS"/*.ts; do
      [ -f "$helper" ] || continue
      BASENAME=$(basename "$helper")
      TARGET=".e2e-tests/shared/helpers/$BASENAME"
      # 仅在目标不存在或源文件更新时复制
      if [ ! -f "$TARGET" ] || [ "$helper" -nt "$TARGET" ]; then
        cp "$helper" "$TARGET"
      fi
    done
  fi
fi

# ── 知识索引初始化 ──
if [ -d ".e2e-tests/shared" ] && [ ! -f ".e2e-tests/shared/knowledge-index.md" ]; then
  cat > .e2e-tests/shared/knowledge-index.md << 'TEMPLATE'
# Knowledge Index

> 自动维护，各 skill 执行后回写。最后更新: -

## 环境配置

| 环境名 | 文件路径 | base_url | 认证方式 | 状态 |
|--------|---------|----------|---------|------|

## 自动化脚本

| ID | 类型 | 覆盖场景 | 文件路径 | 可靠度 | 最后执行 | 结果 |
|----|------|---------|---------|--------|---------|------|

## 认证脚本

| 环境 | 文件路径 | 认证方式 | 返回物 | 最后验证 |
|------|---------|---------|--------|---------|

## 活跃剧本

| scenario-slug | 描述 | 最后 run | 状态 | case 数 |
|--------------|------|---------|------|---------|

## 已知陷阱（Top 5 Active）

| ID | 类型 | 摘要 | 涉及服务 | 规避方式 |
|----|------|------|---------|---------|

## 项目技术栈

| 维度 | 值 |
|------|---|
| 前端框架 | - |
| 后端框架 | - |
| 测试框架 | - |
| 包管理器 | - |
| 部署方式 | - |
TEMPLATE
fi

# ── 项目环境自动发现（轻量探测） ──
# 仅在环境配置为空且项目根目录存在常见配置文件时触发
ENV_COUNT=$(ls .e2e-tests/shared/env/*.yaml 2>/dev/null | wc -l | tr -d ' ')
if [ "$ENV_COUNT" -eq 0 ]; then
  DETECTED=""

  # 探测 package.json 中的 dev server / proxy
  if [ -f "package.json" ]; then
    # 检测 dev 命令暗示的端口
    DEV_PORT=$(grep -oP '"dev":\s*"[^"]*--port\s+\K\d+' package.json 2>/dev/null || echo "")
    PROXY_TARGET=$(grep -oP '"proxy":\s*"\K[^"]+' package.json 2>/dev/null || echo "")
    if [ -n "$DEV_PORT" ]; then
      DETECTED="${DETECTED}dev_port=${DEV_PORT} "
    fi
    if [ -n "$PROXY_TARGET" ]; then
      DETECTED="${DETECTED}api_proxy=${PROXY_TARGET} "
    fi
  fi

  # 探测 .env / .env.local / .env.development
  for ENVFILE in .env .env.local .env.development .env.test; do
    if [ -f "$ENVFILE" ]; then
      BASE_URL=$(grep -oP '(?:VITE_|NEXT_PUBLIC_|REACT_APP_)?(?:BASE_URL|API_URL|API_BASE_URL)\s*=\s*\K\S+' "$ENVFILE" 2>/dev/null | head -1 || echo "")
      if [ -n "$BASE_URL" ]; then
        DETECTED="${DETECTED}base_url=${BASE_URL}(from ${ENVFILE}) "
        break
      fi
    fi
  done

  # 探测 playwright.config.ts / playwright.config.js
  for PW_CONFIG in playwright.config.ts playwright.config.js; do
    if [ -f "$PW_CONFIG" ]; then
      PW_BASE=$(grep -oP 'baseURL:\s*['\''"`]\K[^'\''"`]+' "$PW_CONFIG" 2>/dev/null | head -1 || echo "")
      if [ -n "$PW_BASE" ]; then
        DETECTED="${DETECTED}pw_baseURL=${PW_BASE} "
      fi
      DETECTED="${DETECTED}playwright_config=${PW_CONFIG} "
      break
    fi
  done

  # 探测包管理器
  if [ -f "pnpm-lock.yaml" ]; then
    DETECTED="${DETECTED}pkg_manager=pnpm "
  elif [ -f "yarn.lock" ]; then
    DETECTED="${DETECTED}pkg_manager=yarn "
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    DETECTED="${DETECTED}pkg_manager=bun "
  elif [ -f "package-lock.json" ]; then
    DETECTED="${DETECTED}pkg_manager=npm "
  fi

  # 探测前端框架
  if [ -f "package.json" ]; then
    if grep -q '"next"' package.json 2>/dev/null; then
      DETECTED="${DETECTED}frontend=Next.js "
    elif grep -q '"nuxt"' package.json 2>/dev/null; then
      DETECTED="${DETECTED}frontend=Nuxt "
    elif grep -q '"react"' package.json 2>/dev/null; then
      DETECTED="${DETECTED}frontend=React "
    elif grep -q '"vue"' package.json 2>/dev/null; then
      DETECTED="${DETECTED}frontend=Vue "
    elif grep -q '"svelte"' package.json 2>/dev/null; then
      DETECTED="${DETECTED}frontend=Svelte "
    elif grep -q '"@angular/core"' package.json 2>/dev/null; then
      DETECTED="${DETECTED}frontend=Angular "
    fi
  fi

  if [ -n "$DETECTED" ]; then
    echo ""
    echo "### 🔍 项目环境自动发现"
    echo ""
    echo "检测到以下环境线索（可在首次测试时自动生成环境配置）："
    for item in $DETECTED; do
      KEY=$(echo "$item" | cut -d= -f1)
      VAL=$(echo "$item" | cut -d= -f2-)
      echo "  - ${KEY}: ${VAL}"
    done
    echo ""
    echo "> 使用 /e2e-tester:e2e 或 /e2e-tester:quick-run 时会自动利用这些信息生成环境配置。"
  fi
fi

# ── 展示 QA 工作台状态 ──
if [ -d ".e2e-tests" ]; then
  echo "---"
  echo "## QA 工作台状态"
  echo ""

  SCENARIO_COUNT=$(find .e2e-tests/scenarios -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  echo "- 测试剧本: ${SCENARIO_COUNT} 个"

  ACTIVE_RUNS=$(find .e2e-tests/scenarios -path "*/runs/*/index.md" 2>/dev/null | wc -l | tr -d ' ')
  echo "- 可接续执行: ${ACTIVE_RUNS} 个"

  if [ -f ".e2e-tests/shared/quality-ledger.md" ]; then
    echo "- quality-ledger: 已存在"
  else
    echo "- quality-ledger: 未初始化"
  fi

  if [ -f ".e2e-tests/shared/registry/index.yaml" ]; then
    echo "- registry: 已存在"
  else
    echo "- registry: 未初始化"
  fi

  ENV_COUNT=$(ls .e2e-tests/shared/env/*.yaml 2>/dev/null | wc -l | tr -d ' ')
  echo "- 环境配置: ${ENV_COUNT} 个"

  SCRIPT_COUNT=$(find .e2e-tests/shared/automation -name "*.ts" 2>/dev/null | wc -l | tr -d ' ')
  echo "- 沉淀脚本: ${SCRIPT_COUNT} 个"

  AUTH_COUNT=$(find .e2e-tests/shared/automation/auth -name "*.ts" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$AUTH_COUNT" -gt 0 ]; then
    echo "- 认证脚本: ${AUTH_COUNT} 个"
  fi

  if [ -d ".e2e-tests/shared/reports" ] && [ "$(ls -A .e2e-tests/shared/reports 2>/dev/null)" ]; then
    LATEST_REPORT=$(ls -t .e2e-tests/shared/reports 2>/dev/null | head -n 1)
    echo "- 最近回归报告: ${LATEST_REPORT}"
  fi

  # ── 知识摘要（从 knowledge-index.md 提取关键信息）──
  if [ -f ".e2e-tests/shared/knowledge-index.md" ]; then
    echo ""
    echo "### 知识召回摘要"

    # 提取环境配置（非空行）
    ENV_ENTRIES=$(sed -n '/^## 环境配置/,/^## /{/^|[^-]/p}' .e2e-tests/shared/knowledge-index.md 2>/dev/null | grep -v "^| 环境名" | head -3)
    if [ -n "$ENV_ENTRIES" ]; then
      echo ""
      echo "**可用环境：**"
      echo "$ENV_ENTRIES"
    fi

    # 提取可用脚本（前 5 个）
    SCRIPT_ENTRIES=$(sed -n '/^## 自动化脚本/,/^## /{/^|[^-]/p}' .e2e-tests/shared/knowledge-index.md 2>/dev/null | grep -v "^| ID" | head -5)
    if [ -n "$SCRIPT_ENTRIES" ]; then
      echo ""
      echo "**可用脚本（Top 5）：**"
      echo "$SCRIPT_ENTRIES"
    fi

    # 提取已知陷阱
    TRAP_ENTRIES=$(sed -n '/^## 已知陷阱/,/^## /{/^|[^-]/p}' .e2e-tests/shared/knowledge-index.md 2>/dev/null | grep -v "^| ID" | head -3)
    if [ -n "$TRAP_ENTRIES" ]; then
      echo ""
      echo "**注意陷阱：**"
      echo "$TRAP_ENTRIES"
    fi

    # 提取项目技术栈（只展示非空行）
    STACK_ENTRIES=$(sed -n '/^## 项目技术栈/,/^$/{/^|[^-|维]/p}' .e2e-tests/shared/knowledge-index.md 2>/dev/null | grep -v "| - |" | head -5)
    if [ -n "$STACK_ENTRIES" ]; then
      echo ""
      echo "**技术栈：**"
      echo "$STACK_ENTRIES"
    fi
  fi

  echo ""
  echo "支持的 QA 工作场景：快速验收 / 新功能验收 / 发布验证 / 回归 / 影响分析 / 缺陷复现 / 专项验证 / 脚本维护"
  echo "---"
  echo ""
fi
