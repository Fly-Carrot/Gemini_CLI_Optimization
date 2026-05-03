#!/usr/bin/env node

import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const BEGIN_SNIPPET_MARKER =
  '<!-- BEGIN GEMINI2 CANONICAL SHARED-FABRIC OVERRIDE -->';
export const END_SNIPPET_MARKER =
  '<!-- END GEMINI2 CANONICAL SHARED-FABRIC OVERRIDE -->';

export function getRepoRoot(importMetaUrl) {
  const scriptPath = fileURLToPath(importMetaUrl);
  return path.resolve(path.dirname(scriptPath), '..');
}

export function expandHome(value) {
  if (!value) {
    return value;
  }
  if (value === '~') {
    return os.homedir();
  }
  if (value.startsWith('~/')) {
    return path.join(os.homedir(), value.slice(2));
  }
  return value;
}

export function collapseHome(value) {
  const home = os.homedir();
  if (value === home) {
    return '~';
  }
  if (value.startsWith(`${home}/`)) {
    return `~/${value.slice(home.length + 1)}`;
  }
  return value;
}

export function resolveAgainst(baseDir, value) {
  const expanded = expandHome(value);
  return path.isAbsolute(expanded)
    ? path.normalize(expanded)
    : path.resolve(baseDir, expanded);
}

function isRecord(value) {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

export function deepMerge(base, overlay) {
  if (!isRecord(base) || !isRecord(overlay)) {
    return overlay;
  }

  const merged = { ...base };
  for (const [key, value] of Object.entries(overlay)) {
    if (isRecord(merged[key]) && isRecord(value)) {
      merged[key] = deepMerge(merged[key], value);
    } else {
      merged[key] = value;
    }
  }
  return merged;
}

export async function readJsonFile(filePath) {
  const raw = await fs.readFile(filePath, 'utf-8');
  return JSON.parse(raw);
}

export async function pathExists(targetPath) {
  try {
    await fs.access(targetPath);
    return true;
  } catch {
    return false;
  }
}

export async function loadRuntimeConfig(basePath, overlayPath) {
  const configs = [];
  const baseExists = await pathExists(basePath);
  if (baseExists) {
    configs.push({
      path: path.resolve(basePath),
      data: await readJsonFile(basePath),
    });
  }
  if (overlayPath && (await pathExists(overlayPath))) {
    configs.push({
      path: path.resolve(overlayPath),
      data: await readJsonFile(overlayPath),
    });
  }

  const merged = configs.reduce(
    (current, entry) => deepMerge(current, entry.data),
    {},
  );
  return {
    configs,
    merged,
  };
}

export async function writeJsonFileAtomic(filePath, value) {
  await fs.mkdir(path.dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  try {
    await fs.writeFile(
      tempPath,
      `${JSON.stringify(value, null, 2)}\n`,
      'utf-8',
    );
    await fs.rename(tempPath, filePath);
  } finally {
    await fs.unlink(tempPath).catch(() => undefined);
  }
}

export async function loadCanonicalSnippet(repoRoot) {
  const snippetPath = path.join(repoRoot, 'gemini-2-canonical-snippet.md');
  const snippet = await fs.readFile(snippetPath, 'utf-8');
  return { snippetPath, snippet: snippet.trim() };
}

export function wrapManagedSnippet(snippet) {
  return `${BEGIN_SNIPPET_MARKER}\n${snippet.trim()}\n${END_SNIPPET_MARKER}`;
}

export async function ensureSnippetBlock(targetPath, snippet) {
  const wrapped = wrapManagedSnippet(snippet);
  let existing = '';
  try {
    existing = await fs.readFile(targetPath, 'utf-8');
  } catch {
    existing = '';
  }

  let next = existing;
  const blockPattern = new RegExp(
    `${BEGIN_SNIPPET_MARKER}[\\s\\S]*?${END_SNIPPET_MARKER}`,
    'm',
  );

  if (blockPattern.test(existing)) {
    next = existing.replace(blockPattern, wrapped);
  } else if (existing.includes('CANONICAL SHARED-FABRIC OVERRIDE')) {
    return {
      status: 'existing-manual-block',
      targetPath,
    };
  } else if (existing.trim().length === 0) {
    next = `${wrapped}\n`;
  } else {
    next = `${wrapped}\n\n${existing}`;
  }

  await fs.mkdir(path.dirname(targetPath), { recursive: true });
  await fs.writeFile(targetPath, next, 'utf-8');
  return {
    status: blockPattern.test(existing) ? 'replaced' : 'inserted',
    targetPath,
  };
}

export function relativeToRepo(repoRoot, targetPath) {
  return path.relative(repoRoot, targetPath) || '.';
}

export function nowIso() {
  return new Date().toISOString();
}
