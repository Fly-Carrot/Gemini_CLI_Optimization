# Everything Claude Code Local Fusion Assessment

## What This Repository Mainly Is

Everything Claude Code is not primarily a model runtime like Gemini CLI itself.

It is mainly a cross-harness operating layer that packages:

- agents
- skills
- commands
- hooks
- rules
- MCP configs
- harness-specific adapters for Claude, Codex, Gemini, Cursor, OpenCode, and others

Local evidence from the cloned repo:

- 48 agent files
- 288 skill files
- 79 command files
- 89 rule files
- 136 script files
- harness-specific directories such as `.gemini/`, `.codex/`, `.claude/`, `.cursor/`, `.opencode/`

So in plain words:

ECC is a reusable workflow/content system for AI coding harnesses, not a replacement for Gemini CLI's core runtime.

## What Is Most Useful For Gemini

### High-value, low-risk

These are the best candidates to reuse first:

1. `.gemini/GEMINI.md`
   - a Gemini-specific instruction layer
   - useful as a project-level behavior overlay

2. `scripts/gemini-adapt-agents.js`
   - directly shows how ECC adapts agent frontmatter/tool names for Gemini compatibility
   - strong evidence that ECC already thinks in terms of a Gemini bridge rather than Claude-only assumptions

3. Selected skills
   - `skills/strategic-compact/`
   - `skills/continuous-learning-v2/`
   - `skills/search-first/`
   - `skills/agent-harness-construction/`
   - `skills/agent-introspection-debugging/`

4. Selected contexts
   - `contexts/dev.md`
   - `contexts/review.md`
   - `contexts/research.md`

These align well with the Gemini-first roadmap we already started:

- session lifecycle
- context compaction
- reusable workflow guidance
- better harness introspection

### Medium-value, medium-risk

These are worth studying before porting:

1. `hooks/hooks.json`
   - useful for lifecycle design ideas
   - too broad to install wholesale

2. `scripts/hooks/*`
   - useful implementation references for session-start / session-end / compact / observer flows
   - may need substantial translation into Gemini-native lifecycle hooks

3. `commands/`
   - useful as prompt/macros or command taxonomy
   - not a direct drop-in for Gemini CLI

### Low-value or high-risk for direct fusion

Avoid full direct import of:

1. full installer flows
2. full hook registration surface
3. full multi-harness plugin layout
4. broad `settings.json` mutation logic

Reason:

- too invasive
- too Claude/plugin-oriented
- likely to duplicate behavior we already manage in shared fabric
- risks runtime noise, duplicated hooks, and operational confusion

## Best Gemini-First Fusion Plan

### Layer 1: Reference and adapt

Borrow patterns from ECC without changing Gemini CLI architecture:

- compact strategy
- session persistence ideas
- learning extraction ideas
- review and planning workflows

### Layer 2: Add a Gemini compatibility bridge

Create Gemini-native equivalents for:

- session start hook injection
- session end persistence
- pre-compact checkpointing
- optional workflow command aliases

### Layer 3: Keep Gemini runtime ownership inside Gemini CLI

Do not replace Gemini CLI's runtime with ECC.

Instead:

- Gemini CLI remains the runtime
- ECC provides reusable behavior/content modules
- shared fabric remains the orchestration/sync layer

## Recommended Next Targets Inside ECC

If we continue local analysis, the best files to inspect next are:

1. `hooks/hooks.json`
2. `scripts/hooks/`
3. `skills/strategic-compact/`
4. `skills/continuous-learning-v2/`
5. `scripts/gemini-adapt-agents.js`
6. `.gemini/GEMINI.md`

## Bottom Line

ECC is best treated as:

- a pattern library
- a workflow/content pack
- a Gemini compatibility reference

It is not the thing we should merge wholesale into Gemini CLI.
