# Gemini-2 Archive

This repository is archived. It preserves the old Gemini-2 launcher,
bootstrap kit, desktop shell wrappers, workflow notes, and migration assets
that were built around a customized Gemini CLI fork.

The active recommendation is to use the official Gemini CLI directly:

```bash
gemini
```

## Repository roles

- Core fork: [Fly-Carrot/gemini-cli](https://github.com/Fly-Carrot/gemini-cli)
  - edit this when you want to change Gemini-2 runtime behavior, CLI commands, loop, skills, agents, shell UX, or upstream compatibility logic
- Archive and system wrapper: [Fly-Carrot/Gemini_CLI_Optimization](https://github.com/Fly-Carrot/Gemini_CLI_Optimization)
  - edit this when you want to change the `gemini-2` launcher, bootstrap kit, deployment flow, migration notes, macOS shell wrapper source, or workflow documentation

## Archive contents

- Historical Gemini-2 launcher files and runtime configuration
- Bootstrap and profile export/import scripts in `scripts/`
- macOS shell app source in `macos/`
- Workflow, evaluation, and integration notes
- The old Gemini-2 fork checkout in `ref structure/gemini-cli`

## Current daily entrypoint

- Official Gemini CLI: `/opt/homebrew/bin/gemini`
- Archived Gemini-2 materials remain here only for reference and rollback

## Core repositories

- Gemini-2 fork: [Fly-Carrot/gemini-cli](https://github.com/Fly-Carrot/gemini-cli)
- Upstream base: [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)

## Archive status

- This repository is intended for historical reference only.
- GitHub archival should prevent future active development here.
- See [ARCHIVE_MANIFEST.md](/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/ARCHIVE_MANIFEST.md) for the final linked fork snapshot.

## What is intentionally not vendored

- `ref structure/` cloned repositories
- `.gemini2-state/` generated runtime state
- machine-local config such as `gemini-2-runtime.local.json`
- built `.app` bundles

See [ARCHIVE_MANIFEST.md](/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/ARCHIVE_MANIFEST.md) for the exact Gemini-2 fork commit linked to this archive snapshot.
