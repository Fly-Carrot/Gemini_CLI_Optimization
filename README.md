# Gemini CLI Optimization Archive

This repository archives the workspace-level Gemini-2 launcher, bootstrap kit, desktop shell wrappers, workflow notes, and migration assets that sit around the core Gemini CLI fork.

## Repository roles

- Core fork: [Fly-Carrot/gemini-cli](https://github.com/Fly-Carrot/gemini-cli)
  - edit this when you want to change Gemini-2 runtime behavior, CLI commands, loop, skills, agents, shell UX, or upstream compatibility logic
- Archive and system wrapper: [Fly-Carrot/Gemini_CLI_Optimization](https://github.com/Fly-Carrot/Gemini_CLI_Optimization)
  - edit this when you want to change the `gemini-2` launcher, bootstrap kit, deployment flow, migration notes, macOS shell wrapper source, or workflow documentation

## Daily entrypoints

- Run Gemini-2 locally with [gemini-2](/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/gemini-2)
- Core source checkout lives in [ref structure/gemini-cli](</Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/ref structure/gemini-cli>)
- Restore or migrate the system with [gemini2_bootstrap_kit.md](/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/gemini2_bootstrap_kit.md)

## Core repositories

- Gemini-2 fork: [Fly-Carrot/gemini-cli](https://github.com/Fly-Carrot/gemini-cli)
- Upstream base: [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)

## What is archived here

- `gemini-2` launcher and runtime configuration
- bootstrap and profile export/import scripts in `scripts/`
- macOS shell app source in `macos/`
- workflow, evaluation, and integration notes
- canonical snippet and deployment guides

## What is intentionally not vendored

- `ref structure/` cloned repositories
- `.gemini2-state/` generated runtime state
- machine-local config such as `gemini-2-runtime.local.json`
- built `.app` bundles

See [ARCHIVE_MANIFEST.md](/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/ARCHIVE_MANIFEST.md) for the exact Gemini-2 fork commit linked to this archive snapshot.
