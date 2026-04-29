#!/usr/bin/env node
/**
 * Registry YAML 校验工具
 * 用法: npx tsx .e2e-tests/shared/helpers/registry-validate.ts [--fix] [--domain <domain>]
 *
 * 功能:
 * - 校验 index.yaml 结构完整性
 * - 校验每个 domain.yaml 中脚本条目的必填字段
 * - 检查脚本文件是否存在
 * - 检查 script_count 与实际条目数一致
 * - --fix 模式: 自动修复 script_count、last_updated、stale 标记
 */

import { readFileSync, existsSync, writeFileSync, readdirSync } from 'fs';
import { resolve, join } from 'path';
import { parse, stringify } from 'yaml';

const REGISTRY_DIR = resolve(process.cwd(), '.e2e-tests/shared/registry');
const AUTOMATION_DIR = resolve(process.cwd(), '.e2e-tests/shared/automation');

// ── 必填字段定义 ──
const REQUIRED_FIELDS = [
  'type', 'path', 'scenario', 'business_scenario', 'risk_level',
  'api_endpoints', 'source_paths', 'persona',
  'execution_mode', 'parallel_safe', 'recommended_workers',
  'retry_policy', 'trace_policy', 'abstraction_mode', 'automation_confidence'
];

const ENUM_VALUES: Record<string, string[]> = {
  type: ['api-script', 'e2e-script'],
  risk_level: ['High', 'Medium', 'Low'],
  execution_mode: ['serial', 'parallel'],
  retry_policy: ['none', 'on-failure-once', 'flaky-only'],
  trace_policy: ['off', 'on-failure', 'on-retry', 'always'],
  abstraction_mode: ['inline', 'helper', 'page-object', 'keyword'],
  automation_confidence: ['high', 'medium', 'low'],
  export_confidence: ['high', 'medium', 'low'],
};

interface ValidationError {
  file: string;
  script?: string;
  field: string;
  message: string;
  severity: 'error' | 'warning';
}

interface FixAction {
  file: string;
  field: string;
  action: string;
}

const args = process.argv.slice(2);
const fixMode = args.includes('--fix');
const domainFilter = args.includes('--domain') ? args[args.indexOf('--domain') + 1] : null;

const errors: ValidationError[] = [];
const fixes: FixAction[] = [];

function today(): string {
  return new Date().toISOString().split('T')[0];
}

// ── 校验 index.yaml ──
function validateIndex(): Record<string, any> | null {
  const indexPath = join(REGISTRY_DIR, 'index.yaml');
  if (!existsSync(indexPath)) {
    errors.push({ file: 'index.yaml', field: '-', message: '文件不存在', severity: 'error' });
    return null;
  }

  const content = readFileSync(indexPath, 'utf-8');
  const index = parse(content);

  if (!index.version) {
    errors.push({ file: 'index.yaml', field: 'version', message: '缺少 version 字段', severity: 'error' });
  }
  if (!index.domains || typeof index.domains !== 'object') {
    errors.push({ file: 'index.yaml', field: 'domains', message: '缺少或无效的 domains 字段', severity: 'error' });
  }

  return index;
}

// ── 校验域 YAML ──
function validateDomain(domain: string, indexEntry: any) {
  const domainPath = join(REGISTRY_DIR, `${domain}.yaml`);
  if (!existsSync(domainPath)) {
    errors.push({ file: `${domain}.yaml`, field: '-', message: '域注册表文件不存在但 index 中已引用', severity: 'error' });
    return;
  }

  const content = readFileSync(domainPath, 'utf-8');
  const data = parse(content);

  if (!data || !data.scripts || !Array.isArray(data.scripts)) {
    errors.push({ file: `${domain}.yaml`, field: 'scripts', message: '缺少或无效的 scripts 数组', severity: 'error' });
    return;
  }

  // 校验 script_count
  const actualCount = data.scripts.length;
  if (indexEntry && indexEntry.script_count !== actualCount) {
    errors.push({
      file: `${domain}.yaml`,
      field: 'script_count',
      message: `index 记录 ${indexEntry.script_count}，实际 ${actualCount}`,
      severity: 'warning'
    });
    if (fixMode) {
      indexEntry.script_count = actualCount;
      fixes.push({ file: 'index.yaml', field: `domains.${domain}.script_count`, action: `${indexEntry.script_count} → ${actualCount}` });
    }
  }

  // 逐脚本校验
  for (const script of data.scripts) {
    const scriptId = script.scenario || script.path || '(unknown)';

    // 必填字段
    for (const field of REQUIRED_FIELDS) {
      if (script[field] === undefined || script[field] === null || script[field] === '') {
        errors.push({
          file: `${domain}.yaml`,
          script: scriptId,
          field,
          message: `必填字段缺失`,
          severity: 'error'
        });
      }
    }

    // 枚举值校验
    for (const [field, allowed] of Object.entries(ENUM_VALUES)) {
      if (script[field] !== undefined && script[field] !== null && !allowed.includes(script[field])) {
        errors.push({
          file: `${domain}.yaml`,
          script: scriptId,
          field,
          message: `无效值 "${script[field]}"，允许: ${allowed.join(' / ')}`,
          severity: 'error'
        });
      }
    }

    // 文件存在性
    if (script.path) {
      const scriptPath = resolve(process.cwd(), script.path);
      if (!existsSync(scriptPath)) {
        errors.push({
          file: `${domain}.yaml`,
          script: scriptId,
          field: 'path',
          message: `脚本文件不存在: ${script.path}`,
          severity: 'warning'
        });
        // stale 标记
        if (fixMode && !script.stale) {
          script.stale = true;
          fixes.push({ file: `${domain}.yaml`, field: `${scriptId}.stale`, action: 'false → true' });
        }
      }
    }

    // type 与文件名后缀匹配
    if (script.type && script.path) {
      if (script.type === 'api-script' && !script.path.endsWith('.test.ts')) {
        errors.push({
          file: `${domain}.yaml`,
          script: scriptId,
          field: 'path',
          message: `api-script 应以 .test.ts 结尾`,
          severity: 'warning'
        });
      }
      if (script.type === 'e2e-script' && !script.path.endsWith('.spec.ts')) {
        errors.push({
          file: `${domain}.yaml`,
          script: scriptId,
          field: 'path',
          message: `e2e-script 应以 .spec.ts 结尾`,
          severity: 'warning'
        });
      }
    }
  }

  // --fix: 写回域文件
  if (fixMode) {
    data.last_updated = today();
    writeFileSync(domainPath, stringify(data), 'utf-8');
  }
}

// ── 主流程 ──
function main() {
  console.log(`🔍 Registry 校验${fixMode ? ' (--fix 模式)' : ''}`);
  console.log(`   目录: ${REGISTRY_DIR}\n`);

  const index = validateIndex();
  if (!index || !index.domains) {
    printResults();
    return;
  }

  const domains = domainFilter ? [domainFilter] : Object.keys(index.domains);

  for (const domain of domains) {
    validateDomain(domain, index.domains[domain]);
  }

  // 检查 registry 目录中未在 index 中注册的 YAML
  if (!domainFilter) {
    const files = readdirSync(REGISTRY_DIR).filter(f => f.endsWith('.yaml') && f !== 'index.yaml' && f !== 'suites.yaml');
    for (const file of files) {
      const domain = file.replace('.yaml', '');
      if (!index.domains[domain]) {
        errors.push({
          file: 'index.yaml',
          field: `domains.${domain}`,
          message: `域文件 ${file} 存在但未在 index 中注册`,
          severity: 'warning'
        });
        if (fixMode) {
          index.domains[domain] = { file: `${domain}.yaml`, script_count: 0, last_updated: today() };
          fixes.push({ file: 'index.yaml', field: `domains.${domain}`, action: '添加到 index' });
        }
      }
    }
  }

  // --fix: 写回 index
  if (fixMode) {
    index.last_updated = today();
    const indexPath = join(REGISTRY_DIR, 'index.yaml');
    writeFileSync(indexPath, stringify(index), 'utf-8');
  }

printResults();
}

function printResults() {
  const errorCount = errors.filter(e => e.severity === 'error').length;
  const warnCount = errors.filter(e => e.severity === 'warning').length;

  if (errors.length === 0) {
    console.log('✅ 校验通过，无问题');
  } else {
    console.log(`\n📋 校验结果: ${errorCount} 错误, ${warnCount} 警告\n`);

    for (const err of errors) {
      const icon = err.severity === 'error' ? '❌' : '⚠️';
      const scriptInfo = err.script ? ` [${err.script}]` : '';
      console.log(`  ${icon} ${err.file}${scriptInfo} → ${err.field}: ${err.message}`);
    }
  }

  if (fixMode && fixes.length > 0) {
    console.log(`\n🔧 已修复 ${fixes.length} 项:`);
    for (const fix of fixes) {
      console.log(`  ✓ ${fix.file} → ${fix.field}: ${fix.action}`);
    }
  }

  console.log('');
  process.exit(errorCount > 0 ? 1 : 0);
}

main();
