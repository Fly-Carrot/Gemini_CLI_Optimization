# Gemini-2 History Migration Notes

## What Changed

The `gemini-2` launcher previously changed into the cloned source repo before starting the modified CLI.

That caused old `gemini-2` state to be written under the source-tree bucket:

- `~/.gemini/history/gemini-cli`
- `~/.gemini/tmp/gemini-cli`

The launcher now preserves the caller's current working directory, so future sessions should align with the same project identity model as official `gemini`.

## What Still Needs Migration

Old custom sessions still exist in the source-tree bucket.

Observed local files:

- `~/.gemini/history/gemini-cli/.project_root`
- `~/.gemini/tmp/gemini-cli/.project_root`
- `~/.gemini/tmp/gemini-cli/chats/session-2026-04-25T03-10-2371059b.jsonl`
- `~/.gemini/tmp/gemini-cli/logs.json`

## Prepared Dry-Run Tool

Use:

- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/prepare_gemini2_history_migration.sh`

Examples:

- `./prepare_gemini2_history_migration.sh`
- `./prepare_gemini2_history_migration.sh /Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization`
- `./prepare_gemini2_history_migration.sh /Users/david_chen/Desktop/MCP_Hub`

## Current Recommendation

1. Run the dry-run script first.
2. Choose the real target project root you want official `gemini` and `gemini-2` to share.
3. Use copy-first migration, not move-first migration.
4. Resume/list sessions with official `gemini` after copying.
5. Only then decide whether to clean the old `gemini-cli` bucket.
