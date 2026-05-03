# Gemini-2 Shared Fabric Feature Priorities

## Goal

This document answers one practical question:

If `gemini-2` is going to become the user's real day-to-day local Gemini CLI replacement, which shared-fabric skill capabilities are worth integrating into the runtime itself?

## Current Shared Fabric Reality

The current shared framework is **not** centered around a large hand-written local `skills/` tree inside `global-agent-fabric`.

Instead, it is built from four layers:

1. **Governance and sync core**
   - `sync/boot-sequence.md`
   - `sync/runtime-map.yaml`
   - `rules/global/gemini-global.md`
   - `scripts/sync/*.py`

2. **External large skill repository**
   - `/Users/david_chen/Antigravity_Skills/awesome-skills`
   - catalog size: `1234` skills

3. **Generated shared-fabric skills**
   - currently the most important one is the generated user-question-profile skill

4. **Memory routing layer**
   - stable reusable knowledge -> `cc-skill-continuous-learning`
   - episodic/process detail -> `mempalace`

So the current system is best described as:

> strong workflow governance + huge external skill library + dual-track memory routing

not:

> a small self-contained local skill pack

## Most Important Insight

If `gemini-2` becomes the default local CLI, the highest-value work is **not** to embed hundreds of skills.

The highest-value work is to embed the **skill operating system**:

- routing
- discovery
- context handling
- memory routing
- workflow execution boundaries

The content skills should mostly remain external and discoverable on demand.

## What Is Already Strong In The Shared Framework

### 1. Boot and lifecycle governance

Current assets:

- preflight validation
- session start sync
- six-stage phase logging
- postflight sync
- user-question-profile writeback

Why it matters:

- this is the backbone that makes the runtime operationally reliable
- if `gemini-2` is the daily driver, this should not remain a manual wrapper habit

### 2. Dual-track memory routing

Current assets:

- `cc-skill-continuous-learning`
- `mempalace`
- `memory/routes.yaml`

Why it matters:

- this already encodes a real memory architecture
- it separates stable reusable knowledge from detailed process traces
- this is much more valuable than generic "chat history"

### 3. User-question-profile distillation

Current assets:

- generated skill: `skills/generated/user-questioning-profile/SKILL.md`
- workspace overlay profile
- postflight compilation pipeline

Why it matters:

- it makes the agent adapt to the user's questioning style without persisting raw prompts
- this is exactly the kind of feature that should feel native inside a replacement CLI

### 4. External skill breadth

Current assets:

- `awesome-skills` catalog with `1234` skills
- domain routing map:
  - data
  - docs
  - engineering
  - audit
  - infrastructure
  - management

Why it matters:

- the library is already large enough that the bottleneck is selection and orchestration, not raw skill count

## Features Worth Adding To Gemini-2

## P0: Must-Have If Gemini-2 Is The Real Replacement

### 1. Native shared-fabric boot/postflight mode

Add a first-class runtime mode where `gemini-2` automatically performs:

- preflight
- sync_all
- phase logging
- postflight
- user-question-profile writeback

Why:

- this removes the gap between "wrapper discipline" and "runtime truth"
- if you use `gemini-2` every day, this should be built in

### 2. Native skill discovery and routing

Add built-in commands like:

- `/skills search <query>`
- `/skills recommend`
- `/workflow route`

Back them with:

- `global-agent-fabric/skills/sources.yaml`
- `awesome-skills/skills_index.json`
- `skills-domain-map.md`

Why:

- right now the framework knows where the skills live, but Gemini CLI does not own that routing experience
- this is the single best bridge from the shared framework into the runtime

### 3. Native context-budget and compaction engine

Shared framework signals strongly point to this need:

- `context-fundamentals`
- `context-degradation`
- `context-compression`
- `context-window-management`
- ECC strategic compact patterns

What to add:

- explicit context budget manager
- file/artifact-aware compaction
- summary sections for decisions, files modified, next steps, open loops

Why:

- without this, `gemini-2` cannot be a trustworthy long-session replacement

### 4. Native memory routing commands

Add a simple built-in memory surface:

- `/learn` -> route stable patterns to continuous-learning
- `/remember` or `/trace` -> route process detail to MemPalace
- `/profile` -> inspect current user-question profile overlay

Why:

- the framework already has the memory architecture
- the runtime needs a usable front door

### 5. Review and audit execution modes

The shared skill library is rich in:

- `code-reviewer`
- `security-scan`
- `error-detective`
- `testing-patterns`

Add runtime presets such as:

- `gemini-2 review`
- `gemini-2 audit`
- `gemini-2 debug`

Why:

- these are high-frequency real workflows
- they should be one command away if `gemini-2` is your daily tool

## P1: Very Worth Adding Soon After P0

### 6. Workflow packs as first-class runtime routes

Best candidates:

- `antigravity-workflows`
- `brainstorming`
- `architecture`
- `docs-architect`

What to add:

- a workflow registry
- a prompt-to-workflow matcher
- step tracking per workflow

Why:

- this gives `gemini-2` a stronger product shape than a raw prompt shell

### 7. Project-aware skill recommendations

Use:

- user-question profile
- workspace type
- git/project signals
- previous task history

to recommend likely relevant skills automatically.

Why:

- the library is too large for manual recall
- recommendation matters more than raw inventory

### 8. Native artifact/report generation

Best candidates:

- `docs-architect`
- audit/report oriented skills
- architecture documentation patterns

What to add:

- one-step report scaffolds for:
  - task summaries
  - architecture assessments
  - review reports
  - migration plans

Why:

- this matches how you actually use the system

## P2: Useful But Should Stay Optional

### 9. Local multi-agent orchestration

Candidates:

- `agent-orchestrator`
- `agent-manager-skill`

Why optional:

- useful for scale
- but not required to make `gemini-2` a strong personal daily replacement
- should come after core lifecycle, context, and memory are stable

### 10. External memory backends beyond current dual-track model

Candidates:

- `agent-memory-mcp`
- `agent-memory-systems`
- `context-manager`

Why optional:

- these are architectural references
- they should inform Gemini's internal memory design, not be blindly bolted on

### 11. Deployment and publishing helpers

Candidates:

- `appdeploy`
- deployment workflows

Why optional:

- valuable, but secondary to runtime reliability and context handling

## Features That Are Not Worth Pulling In Directly

### 1. The whole skill library

Do not embed hundreds of skills into Gemini-2 itself.

Reason:

- discovery and routing are the real problem
- embedding everything would make the runtime bloated and hard to govern

### 2. Full external installers and hook surfaces

Do not directly import large external installer behavior from ECC or other repos.

Reason:

- too invasive
- creates hidden behavior
- conflicts with shared-fabric governance clarity

### 3. Domain-specific skills as runtime core

Do not treat highly domain-specific skills as part of Gemini-2's permanent built-in runtime.

Reason:

- keep the core runtime general
- load specialized content on demand

## Recommended Build Order

### Phase A: Make Gemini-2 operationally first-class

1. native shared-fabric lifecycle
2. native skill discovery/routing
3. native context budget and compaction
4. native memory routing commands

### Phase B: Make Gemini-2 feel smarter in real work

5. review/audit/debug modes
6. workflow packs
7. project-aware recommendations
8. report generation

### Phase C: Add scale features

9. optional multi-agent orchestration
10. optional extended memory systems
11. optional deploy/publish helpers

## Bottom Line

If `gemini-2` is going to replace the local default Gemini CLI, the right optimization target is:

- not "add more standalone skills"
- but "make Gemini-2 the native execution shell for the shared framework's routing, memory, and workflow intelligence"

That is the shortest path from today's system to a real daily-driver runtime.
