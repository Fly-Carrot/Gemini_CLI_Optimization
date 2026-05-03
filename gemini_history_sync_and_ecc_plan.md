# Gemini History Sync And ECC Plan

## Current Findings

- The official Homebrew `gemini` uses the shared user storage root under `~/.gemini`.
- Gemini CLI storage is keyed by the caller's project root, not by the command name itself.
- In the modified source, `Storage` uses the exact runtime target directory for project identity and history/temp paths.
- The previous `gemini-2` launcher forced `cd` into `ref structure/gemini-cli`, which caused its sessions to be associated with the cloned source tree instead of the caller's real project.
- That launcher bug has now been fixed: `gemini-2` keeps the caller's current working directory.

Code evidence:

- `ref structure/gemini-cli/packages/cli/src/gemini.tsx`
- `ref structure/gemini-cli/packages/core/src/config/storage.ts`
- `gemini-2`

## History Sync Assessment

### Future sessions

For future runs, `gemini` and `gemini-2` can now align much more naturally:

- both use `~/.gemini` as the user storage root
- both derive project identity from the runtime working directory
- therefore, if both commands are launched from the same project directory, they should resolve to the same project storage bucket

### Existing old `gemini-2` sessions

There is evidence of earlier `gemini-2` state written under the cloned repo identity:

- `~/.gemini/history/gemini-cli/.project_root`
- `~/.gemini/tmp/gemini-cli/chats/session-2026-04-25T03-10-2371059b.jsonl`

This means old `gemini-2` sessions are not yet merged into the same project bucket used by official `gemini` in other directories.

## Recommended Sync Strategy

### Phase 1: Keep future sessions unified

Status: done

- `gemini-2` no longer overrides the project root by changing directories before startup.

### Phase 2: One-time migration for old `gemini-2` records

Recommended approach:

1. Identify the real target project bucket for the conversations you want to merge into.
2. Create a dry-run inventory of old chat/session files under:
   - `~/.gemini/history/gemini-cli`
   - `~/.gemini/tmp/gemini-cli`
3. Copy, do not move, the relevant old chat/session artifacts into the target project's temp/history bucket.
4. Validate that official `gemini` can resume/list those sessions correctly.
5. Only after validation, decide whether to keep or remove the old duplicated source-tree bucket.

Risk note:

- the installed official CLI is `0.38.2`
- the custom `gemini-2` build is `0.41.0-nightly`

So format compatibility should be validated on copied artifacts first, not assumed.

## How To Use Everything Claude Code

## Key conclusion

Use Everything Claude Code as a reusable pattern library, not as a drop-in replacement architecture.

Why:

- it is explicitly positioned as a cross-harness system for Claude Code, Codex, Cursor, OpenCode, Gemini, and others
- it packages agents, skills, commands, hooks, rules, MCP configs, and cross-platform scripts
- it already contains memory/session hooks and context-compaction guidance
- but its install surface is broad, and public issue reports show that full install can inject many hooks and modify settings in invasive ways

## Recommended adoption model

### Layer A: Reference first

Mine ECC for:

- hook lifecycle design
- skill packaging conventions
- command taxonomy
- reusable agent prompts
- session-start / session-end / pre-compact patterns

Do not blindly install its full runtime into the current environment.

### Layer B: Selective port into Gemini-first runtime

Prioritize borrowing these ideas into the modified Gemini CLI:

1. Session lifecycle hooks
2. Context compaction / strategic compact triggers
3. Reusable workflow commands and skill bundles
4. Optional subagent orchestration patterns

### Layer C: Compatibility bridge

If ECC artifacts prove useful, create a thin compatibility layer for Gemini CLI instead of duplicating Claude Code behavior wholesale.

Candidate bridge surfaces:

- Gemini `SessionStart` / `SessionEnd` hook mapping
- workspace-local skill/rule ingestion
- optional command aliases or prompt templates
- shared fabric aware preflight/postflight wrappers

## Suggested Next Steps

1. Run a dry-run audit of old `gemini-2` session files and choose the exact destination project bucket.
2. Validate chat/session format compatibility between official `gemini` and the modified `gemini-2` on copied test artifacts.
3. Inspect ECC's hook, command, and skills surfaces in more detail and extract only the parts that match the Gemini-first roadmap.
4. Build a small Gemini compatibility layer for:
   - session lifecycle hooks
   - context compaction triggers
   - shared-fabric boot/postflight integration
