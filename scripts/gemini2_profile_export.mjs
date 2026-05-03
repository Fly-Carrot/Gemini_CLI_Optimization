#!/usr/bin/env node

import os from 'node:os';
import path from 'node:path';
import {
  collapseHome,
  getRepoRoot,
  loadCanonicalSnippet,
  loadRuntimeConfig,
  nowIso,
  relativeToRepo,
  writeJsonFileAtomic,
} from './lib/gemini2Bootstrap.mjs';

function parseArgs(argv) {
  const args = {
    outputPath: undefined,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const token = argv[index];
    if (token === '--output' && argv[index + 1]) {
      args.outputPath = argv[index + 1];
      index += 1;
    }
  }
  return args;
}

const repoRoot = getRepoRoot(import.meta.url);
const { outputPath } = parseArgs(process.argv.slice(2));
const baseConfigPath = path.join(repoRoot, 'gemini-2-runtime.json');
const localConfigPath = path.join(repoRoot, 'gemini-2-runtime.local.json');
const outputFile =
  outputPath || path.join(repoRoot, '.gemini2-state', 'gemini-2-profile.bundle.json');

const { configs, merged } = await loadRuntimeConfig(baseConfigPath, localConfigPath);
const { snippetPath, snippet } = await loadCanonicalSnippet(repoRoot);

const bundle = {
  bundleVersion: 1,
  generatedAt: nowIso(),
  machine: {
    hostname: os.hostname(),
    platform: process.platform,
    arch: process.arch,
  },
  repo: {
    root: repoRoot,
    launcherPath: relativeToRepo(repoRoot, path.join(repoRoot, 'gemini-2')),
    runtimeConfigBasePath: relativeToRepo(repoRoot, baseConfigPath),
    runtimeConfigLocalPath: relativeToRepo(repoRoot, localConfigPath),
    canonicalSnippetPath: relativeToRepo(repoRoot, snippetPath),
  },
  runtime: {
    mergedConfig: merged,
    loadedConfigLayers: configs.map((entry) => collapseHome(entry.path)),
  },
  sharedFabric: {
    globalRoot: collapseHome(
      merged.sharedFabricRoot || '~/Antigravity_Skills/global-agent-fabric',
    ),
    canonicalScripts: {
      preflightCheck:
        '~/Antigravity_Skills/global-agent-fabric/scripts/sync/preflight_check.py',
      syncAll:
        '~/Antigravity_Skills/global-agent-fabric/scripts/sync/sync_all.py',
      logTaskPhase:
        '~/Antigravity_Skills/global-agent-fabric/scripts/sync/log_task_phase.py',
      postflightSync:
        '~/Antigravity_Skills/global-agent-fabric/scripts/sync/postflight_sync.py',
    },
    curatedSources: [
      '~/Antigravity_Skills/global-agent-fabric/skills/curated/current-workflow',
      '~/Antigravity_Skills/global-agent-fabric/skills/curated/top50-current-workflow',
      '~/Antigravity_Skills/global-agent-fabric/skills/awesome-skills/skills',
    ],
  },
  snippet,
  manualSteps: [
    'Re-auth Google / Gemini account if the new device has no local auth session yet.',
    'Re-check any external MCP/API credentials that are intentionally stored outside this repo.',
    'Run scripts/gemini2_doctor.sh after import/install to verify the runtime.',
  ],
};

await writeJsonFileAtomic(outputFile, bundle);
process.stdout.write(
  `${JSON.stringify(
    {
      status: 'written',
      output: outputFile,
      bundleVersion: bundle.bundleVersion,
      generatedAt: bundle.generatedAt,
    },
    null,
    2,
  )}\n`,
);
