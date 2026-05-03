#!/usr/bin/env node

import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {
  collapseHome,
  ensureSnippetBlock,
  expandHome,
  getRepoRoot,
  loadCanonicalSnippet,
  readJsonFile,
  writeJsonFileAtomic,
} from './lib/gemini2Bootstrap.mjs';

function parseArgs(argv) {
  const args = {
    bundlePath: undefined,
    globalRoot: undefined,
    geminiMdPath: path.join(os.homedir(), '.gemini', 'GEMINI.md'),
    writeSnippet: true,
    writeLocalConfig: true,
    outputConfigPath: undefined,
  };

  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === '--bundle' && argv[index + 1]) {
      args.bundlePath = argv[index + 1];
      index += 1;
    } else if (token === '--global-root' && argv[index + 1]) {
      args.globalRoot = argv[index + 1];
      index += 1;
    } else if (token === '--gemini-md' && argv[index + 1]) {
      args.geminiMdPath = argv[index + 1];
      index += 1;
    } else if (token === '--output-config' && argv[index + 1]) {
      args.outputConfigPath = argv[index + 1];
      index += 1;
    } else if (token === '--no-snippet') {
      args.writeSnippet = false;
    } else if (token === '--no-local-config') {
      args.writeLocalConfig = false;
    }
  }

  return args;
}

const repoRoot = getRepoRoot(import.meta.url);
const args = parseArgs(process.argv.slice(2));
const bundlePath =
  args.bundlePath ||
  path.join(repoRoot, '.gemini2-state', 'gemini-2-profile.bundle.json');
const bundle = await readJsonFile(bundlePath);
const localConfigPath =
  args.outputConfigPath || path.join(repoRoot, 'gemini-2-runtime.local.json');
const sharedFabricRoot = expandHome(
  args.globalRoot ||
    bundle.sharedFabric?.globalRoot ||
    '~/Antigravity_Skills/global-agent-fabric',
);

let snippetResult = {
  status: 'skipped',
  targetPath: args.geminiMdPath,
};

if (args.writeSnippet) {
  const snippet =
    typeof bundle.snippet === 'string' && bundle.snippet.trim().length > 0
      ? bundle.snippet
      : (await loadCanonicalSnippet(repoRoot)).snippet;
  snippetResult = await ensureSnippetBlock(args.geminiMdPath, snippet);
}

const localConfig = {
  sharedFabricRoot: collapseHome(sharedFabricRoot),
  systemSettingsPath:
    bundle.runtime?.mergedConfig?.systemSettingsPath ||
    './gemini-2-system-settings.json',
  defaults:
    bundle.runtime?.mergedConfig?.defaults || {
      model: 'pro',
      effort: 'high',
      approvalMode: 'yolo',
      loopMode: 'off',
      skillsMode: 'auto',
      agentsMode: 'auto',
    },
  upstreamWatch:
    bundle.runtime?.mergedConfig?.upstreamWatch || {
      enabled: 'on',
      intervalHours: '12',
    },
};

if (args.writeLocalConfig) {
  await writeJsonFileAtomic(localConfigPath, localConfig);
}

await fs.mkdir(path.join(repoRoot, '.gemini2-state'), { recursive: true });
const receiptPath = path.join(
  repoRoot,
  '.gemini2-state',
  'gemini-2-import-receipt.json',
);
await writeJsonFileAtomic(receiptPath, {
  importedAt: new Date().toISOString(),
  bundlePath,
  sharedFabricRoot: localConfig.sharedFabricRoot,
  snippetResult,
  localConfigPath: args.writeLocalConfig ? localConfigPath : null,
});

process.stdout.write(
  `${JSON.stringify(
    {
      status: 'imported',
      bundlePath,
      localConfigWritten: args.writeLocalConfig ? localConfigPath : null,
      snippetResult,
      receiptPath,
    },
    null,
    2,
  )}\n`,
);
