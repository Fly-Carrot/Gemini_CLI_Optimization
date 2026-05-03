#!/usr/bin/env node

import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

function runGit(repoRoot, args, options = {}) {
  return execFileSync('git', ['-C', repoRoot, ...args], {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    timeout: options.timeoutMs ?? 4000,
  }).trim();
}

function safeRunGit(repoRoot, args, options = {}) {
  try {
    return runGit(repoRoot, args, options);
  } catch {
    return '';
  }
}

function readJson(filePath, fallback) {
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch {
    return fallback;
  }
}

function writeJson(filePath, value) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.tmp`;
  fs.writeFileSync(tempPath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
  fs.renameSync(tempPath, filePath);
}

function hoursToMs(hours) {
  return hours * 60 * 60 * 1000;
}

function classifyArchitectureAreas(fileList) {
  const matchers = [
    { prefix: 'packages/core/', label: 'core runtime' },
    { prefix: 'packages/cli/', label: 'CLI and terminal UI' },
    { prefix: 'packages/sdk/', label: 'SDK and session layer' },
    { prefix: 'packages/a2a-server/', label: 'A2A server' },
    { prefix: 'packages/devtools/', label: 'devtools' },
    { prefix: 'packages/vscode-ide-companion/', label: 'VS Code companion' },
    { prefix: 'packages/desktop-shell/', label: 'desktop shell' },
    { prefix: 'docs/', label: 'docs' },
    { prefix: 'scripts/', label: 'build and tooling' },
  ];

  const hits = [];
  for (const matcher of matchers) {
    if (fileList.some((file) => file.startsWith(matcher.prefix))) {
      hits.push(matcher.label);
    }
  }
  return hits;
}

function ensureUpstreamRemote(repoRoot, remoteName, remoteUrl) {
  const currentUrl = safeRunGit(repoRoot, ['remote', 'get-url', remoteName]);
  if (!currentUrl) {
    runGit(repoRoot, ['remote', 'add', remoteName, remoteUrl]);
  }
}

function main() {
  const repoRoot = process.env.GEMINI2_UPSTREAM_REPO_ROOT;
  const stateDir =
    process.env.GEMINI2_STATE_DIR ??
    path.join(os.homedir(), '.gemini2-state');
  const enabled =
    (process.env.GEMINI2_UPSTREAM_CHECK ?? '1').toLowerCase() !== '0';

  if (!enabled || !repoRoot || !fs.existsSync(repoRoot)) {
    process.exit(0);
  }

  const intervalHours = Number.parseInt(
    process.env.GEMINI2_UPSTREAM_CHECK_INTERVAL_HOURS ?? '12',
    10,
  );
  const intervalMs = hoursToMs(
    Number.isFinite(intervalHours) && intervalHours > 0 ? intervalHours : 12,
  );
  const remoteName = process.env.GEMINI2_UPSTREAM_REMOTE ?? 'upstream';
  const remoteUrl =
    process.env.GEMINI2_UPSTREAM_URL ??
    'https://github.com/google-gemini/gemini-cli.git';
  const branch = process.env.GEMINI2_UPSTREAM_BRANCH ?? 'main';
  const stateFile = path.join(stateDir, 'upstream-watch.json');
  const state = readJson(stateFile, {});
  const now = Date.now();

  if (state.lastCheckedAt && now - state.lastCheckedAt < intervalMs) {
    process.exit(0);
  }

  const localHead = safeRunGit(repoRoot, ['rev-parse', 'HEAD']);
  if (!localHead) {
    process.exit(0);
  }

  try {
    ensureUpstreamRemote(repoRoot, remoteName, remoteUrl);
    runGit(repoRoot, ['fetch', '--quiet', remoteName, branch], {
      timeoutMs: 8000,
    });
  } catch (error) {
    writeJson(stateFile, {
      ...state,
      lastCheckedAt: now,
      lastError: 'fetch-failed',
      localHead,
    });
    process.exit(0);
  }

  const upstreamRef = `${remoteName}/${branch}`;
  const upstreamHead = safeRunGit(repoRoot, ['rev-parse', upstreamRef]);
  if (!upstreamHead) {
    writeJson(stateFile, {
      ...state,
      lastCheckedAt: now,
      lastError: 'missing-upstream-head',
      localHead,
    });
    process.exit(0);
  }

  const behindCount = Number.parseInt(
    safeRunGit(repoRoot, ['rev-list', '--count', `${localHead}..${upstreamRef}`]) ||
      '0',
    10,
  );

  const nextState = {
    lastCheckedAt: now,
    localHead,
    upstreamHead,
    behindCount: Number.isFinite(behindCount) ? behindCount : 0,
    lastError: '',
    lastNotifiedUpstreamHead: state.lastNotifiedUpstreamHead ?? '',
  };

  if (!behindCount || localHead === upstreamHead) {
    writeJson(stateFile, nextState);
    process.exit(0);
  }

  const changedFilesRaw = safeRunGit(repoRoot, [
    'diff',
    '--name-only',
    '--no-renames',
    `${localHead}..${upstreamRef}`,
  ]);
  const changedFiles = changedFilesRaw
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
  const areas = classifyArchitectureAreas(changedFiles).slice(0, 3);
  const recentSubjectsRaw = safeRunGit(repoRoot, [
    'log',
    '--format=%s',
    '-n',
    '3',
    `${localHead}..${upstreamRef}`,
  ]);
  const subjects = recentSubjectsRaw
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean)
    .slice(0, 3);

  if (state.lastNotifiedUpstreamHead !== upstreamHead) {
    const areaSummary =
      areas.length > 0 ? areas.join(', ') : 'general repository changes';
    const subjectSummary =
      subjects.length > 0 ? ` Latest: ${subjects.join(' | ')}` : '';
    process.stderr.write(
      `[UPSTREAM_NOTICE] google-gemini/gemini-cli is ${behindCount} commit(s) ahead. Likely touchpoints: ${areaSummary}.${subjectSummary}\n`,
    );
    process.stderr.write(
      `[UPSTREAM_NOTICE] Run: ${path.join(repoRoot, 'scripts/gemini2-upstream-compat-check.sh')}\n`,
    );
    nextState.lastNotifiedUpstreamHead = upstreamHead;
  }

  writeJson(stateFile, nextState);
}

main();
