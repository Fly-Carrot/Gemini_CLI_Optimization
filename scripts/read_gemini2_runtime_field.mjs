#!/usr/bin/env node

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const args = process.argv.slice(2);
const fieldPath = args.at(-1);
const configPathArgs = args.slice(0, -1);

if (configPathArgs.length === 0 || !fieldPath) {
  process.exit(0);
}

function isRecord(value) {
  return typeof value === 'object' && value !== null;
}

function expandHome(value) {
  if (value === '~') {
    return os.homedir();
  }
  if (value.startsWith('~/')) {
    return path.join(os.homedir(), value.slice(2));
  }
  return value;
}

function resolvePathValue(value, configPath) {
  const expanded = expandHome(value);
  if (path.isAbsolute(expanded)) {
    return path.normalize(expanded);
  }
  return path.resolve(path.dirname(configPath), expanded);
}

function deepMerge(base, overlay) {
  if (!isRecord(base) || !isRecord(overlay)) {
    return overlay;
  }

  const merged = { ...base };
  for (const [key, value] of Object.entries(overlay)) {
    if (isRecord(value) && isRecord(merged[key])) {
      merged[key] = deepMerge(merged[key], value);
    } else {
      merged[key] = value;
    }
  }
  return merged;
}

function loadConfigs(configPaths) {
  const loaded = [];
  for (const rawConfigPath of configPaths) {
    if (!rawConfigPath) {
      continue;
    }
    const configPath = path.resolve(rawConfigPath);
    if (!fs.existsSync(configPath)) {
      continue;
    }
    try {
      const raw = fs.readFileSync(configPath, 'utf-8');
      const parsed = JSON.parse(raw);
      loaded.push({ configPath, parsed });
    } catch {
      // Ignore broken or unreadable overlay files so launcher startup stays resilient.
    }
  }
  return loaded;
}

function getFieldValueFromConfigs(loadedConfigs, dottedPath) {
  const segments = dottedPath.split('.');
  let sourcePath;
  let value;

  for (const entry of loadedConfigs) {
    let current = entry.parsed;
    let matched = true;
    for (const segment of segments) {
      if (!isRecord(current) || !(segment in current)) {
        matched = false;
        break;
      }
      current = current[segment];
    }
    if (matched) {
      sourcePath = entry.configPath;
      value = current;
    }
  }

  const merged = loadedConfigs.reduce(
    (current, entry) => deepMerge(current, entry.parsed),
    {},
  );

  let mergedValue = merged;
  for (const segment of segments) {
    if (!isRecord(mergedValue) || !(segment in mergedValue)) {
      mergedValue = undefined;
      break;
    }
    mergedValue = mergedValue[segment];
  }

  return {
    value: mergedValue ?? value,
    sourcePath,
  };
}

function validateField(field, value) {
  switch (field) {
    case 'defaults.model':
      return ['auto', 'flash', 'pro'].includes(value);
    case 'defaults.effort':
      return ['low', 'medium', 'high'].includes(value);
    case 'defaults.approvalMode':
      return ['default', 'yolo', 'strict', 'suggest'].includes(value);
    case 'defaults.loopMode':
      return ['off', 'auto', 'full'].includes(value);
    case 'defaults.skillsMode':
    case 'defaults.agentsMode':
      return ['manual', 'auto', 'full'].includes(value);
    case 'upstreamWatch.enabled':
      return ['on', 'off'].includes(value);
    case 'upstreamWatch.intervalHours':
      return /^\d+$/.test(value);
    default:
      return true;
  }
}

try {
  const loadedConfigs = loadConfigs(configPathArgs);
  if (loadedConfigs.length === 0) {
    process.exit(0);
  }
  const { value, sourcePath } = getFieldValueFromConfigs(
    loadedConfigs,
    fieldPath,
  );

  if (typeof value !== 'string' || !validateField(fieldPath, value)) {
    process.exit(0);
  }

  if (
    sourcePath &&
    (fieldPath === 'sharedFabricRoot' || fieldPath.endsWith('Path'))
  ) {
    process.stdout.write(resolvePathValue(value, sourcePath));
    process.exit(0);
  }

  process.stdout.write(value);
} catch {
  process.exit(0);
}
