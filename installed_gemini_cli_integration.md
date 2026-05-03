# Installed Gemini CLI Integration Notes

## Current installed state

The machine-level `gemini` command currently resolves to:

- binary link: `/opt/homebrew/bin/gemini`
- Homebrew cellar package: `/opt/homebrew/Cellar/gemini-cli/0.38.2`
- runtime entry: `/opt/homebrew/Cellar/gemini-cli/0.38.2/libexec/lib/node_modules/@google/gemini-cli/bundle/gemini.js`

This matters because the installed package is not a checked-out source tree. It is a Homebrew-managed npm artifact with bundled JavaScript output. That makes direct architectural merging possible in principle, but awkward and brittle in practice.

## What was implemented in source

The cloned repository under `ref structure/gemini-cli` now includes a first `SessionOrchestrator` extraction:

- new module: `packages/cli/src/core/sessionOrchestrator.ts`
- tests: `packages/cli/src/core/sessionOrchestrator.test.ts`
- main entrypoint wiring: `packages/cli/src/gemini.tsx`

This change centralizes:

- session run-mode routing (`acp` / `interactive` / `non-interactive`)
- non-interactive stdin preparation
- SessionStart hook context injection for non-interactive runs

It is intentionally a low-risk first slice that creates a future seam for a richer `SessionRuntime` / `ContextBudgetManager`.

## Feasibility of merging into the installed CLI

### Path 1: Safe and recommended

Do not patch the Homebrew installation directly. Instead, run the modified local build when you want the optimized behavior.

Use:

- launcher: `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/run_local_gemini_cli.sh`

This runs:

- `node packages/cli/dist/index.js`

from the modified cloned repository, so you can test the architecture changes without touching `/opt/homebrew`.

### Path 2: Medium-risk replacement

Package the modified source as a custom Homebrew or npm installation and install it side-by-side or over the current formula version.

This is the cleanest “installed” path if you want persistence, because:

- changes survive shell restarts
- package ownership remains explicit
- future upgrades are manageable

But it requires a small release/install pipeline rather than ad-hoc copying.

### Path 3: High-risk hot patch

Directly overwrite files inside:

- `/opt/homebrew/Cellar/gemini-cli/0.38.2/libexec/lib/node_modules/@google/gemini-cli/...`

This is technically possible, but I do **not** recommend it for this specific task because:

- the installed version is `0.38.2`, while the source we changed is `0.41.0-nightly`
- the installed artifact is bundle-oriented, not source-oriented
- Homebrew upgrades or reinstalls will wipe the patch
- the architecture and internal file layout may not match closely enough for a safe cherry-pick

In other words, the idea is portable, but the exact patch is not safely drop-in across those two versions.

## Recommended next step

For practical usage right now, the best bridge is:

1. Keep the Homebrew `gemini` untouched as the stable baseline.
2. Use `run_local_gemini_cli.sh` to exercise the modified architecture.
3. If the behavior proves worthwhile, promote the modified repo into a custom packaged install rather than editing the Cellar in place.

## Upstream sync strategy

Yes, the modified source tree can still stay in sync with official updates, but only if we keep the custom work as a small patch layer instead of letting it sprawl across the repo.

Recommended workflow:

1. Treat `upstream/main` from `google-gemini/gemini-cli` as the canonical source of truth.
2. Keep our architectural changes isolated in a few files with narrow seams.
3. Rebase or cherry-pick our custom commits onto new upstream versions instead of editing built Homebrew artifacts.
4. Rebuild and rerun targeted tests after each upstream sync.

For the current state, this is realistic because the first custom slice is still small:

- `packages/cli/src/gemini.tsx`
- `packages/cli/src/core/sessionOrchestrator.ts`
- `packages/cli/src/core/sessionOrchestrator.test.ts`

That means upstream synchronization is still manageable. The risk goes up only if we start modifying many unrelated modules without preserving clean boundaries.

## Parallel command entry

To avoid replacing the official `gemini` command, the workspace now includes a dedicated parallel launcher:

- launcher: `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/gemini-2`

Behavior:

- `gemini` continues to point at the Homebrew-managed official install
- `gemini-2` points at the modified local source build in `ref structure/gemini-cli`

This side-by-side layout is the safest operational model because it preserves:

- official upgrade compatibility
- stable rollback
- explicit separation between baseline and experimental runtime

Current machine-level bridge:

- symlink installed at `/Users/david_chen/.local/bin/gemini-2`

Because `/Users/david_chen/.local/bin` is already on this machine's `PATH`, `gemini-2` is now callable directly from the shell without replacing the official `gemini` command.

## Verification notes

The modified source tree was validated with:

- successful build of `@google/gemini-cli-core`
- successful build of `@google/gemini-cli`
- passing targeted tests in `packages/cli/src/core/sessionOrchestrator.test.ts`

The installed Homebrew package was inspected only; it was not modified.
