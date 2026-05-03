# Nature-Skills Integration Manual

Date: 2026-05-03

Managed source location:
- `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/local`

Research clone:
- `/Users/david_chen/Desktop/MCP_Hub/nature-skills`

Integrated skills:
- `nature-polishing`
- `nature-data`
- `nature-figure`

## What Was Integrated

The `nature-skills` repository has been integrated into:

1. shared-fabric source registry
2. shared-fabric skill catalog
3. shared-fabric domain routing
4. future Codex skill discovery via local symlinks

The runtime now uses the fabric-managed copy inside `global-agent-fabric/skills/local`.
The original clone under `MCP_Hub/nature-skills` remains useful as an external research/reference copy.

## Storage Topology

The current shared-fabric skill source layout is now:

- `nature-skills`
  - physically copied into:
    - `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/local`
- `awesome-skills`
  - not physically duplicated
  - mounted into the fabric namespace through a symlink:
    - `/Users/david_chen/Antigravity_Skills/global-agent-fabric/skills/external/awesome-skills`

Why this split:

- `nature-skills` is small and curated, so copying it into fabric keeps the specialist pack self-contained.
- `awesome-skills` is large, so symlink mounting keeps the environment clean and avoids duplicating ~100MB of content.

## What This Means in Practice

### In `gemini-2`

These skills are now part of the shared-fabric skill surface from the fabric-managed local copy. They are best treated as specialist academic skills, not default general-purpose skills.

They should be discoverable and recommendable through the existing skill flow:

- `/skills search Nature`
- `/skills recommend polish my manuscript abstract`
- `/skills recommend data availability statement for Nature submission`
- `/skills recommend publication-ready scientific figure`

You can also load them directly:

- `/skills use nature-polishing`
- `/skills use nature-data`
- `/skills use nature-figure`

### In shared-fabric routing

An academic publishing domain has been added:

- `翰林院 · 学术发表（Academic Publishing）`

This means academic / paper / Nature-style queries have a clearer routing target.

### In Codex

The skills were symlinked into:

- `/Users/david_chen/.codex/skills/nature-polishing`
- `/Users/david_chen/.codex/skills/nature-data`
- `/Users/david_chen/.codex/skills/nature-figure`

Important note:

- The current Codex session may not dynamically refresh its already-loaded skill list.
- New Codex sessions should be able to see and use these skills more naturally.

So:
- current live session: maybe not immediately visible in the skill menu
- future/new Codex sessions: yes, expected to work

## Recommended Use Cases

### 1. `nature-polishing`

Use for:
- abstract polishing
- introduction/results/discussion rewriting
- Chinese to English academic polishing
- Nature-style academic tone tightening

Example prompts:
- `Please use nature-polishing to rewrite this abstract into Nature-style English.`
- `请用 nature-polishing 帮我把这段中文论文结果部分润色成 Nature 风格英文。`

### 2. `nature-data`

Use for:
- Data Availability statements
- repository planning
- FAIR metadata checklist
- bilingual data-sharing wording

Example prompts:
- `Use nature-data to draft a Nature-ready Data Availability statement.`
- `请用 nature-data 帮我把这个数据可用性声明改成 Nature 投稿风格。`

### 3. `nature-figure`

Use for:
- Nature-style matplotlib figures
- scientific multi-panel layouts
- academic paper plots

Example prompts:
- `Use nature-figure to design a Nature-style multi-panel matplotlib figure from this result structure.`
- `请用 nature-figure 帮我规划一个 Nature 风格的多面板科研图。`

## Best Way to Call Them in `gemini-2`

### Safe and explicit

If you want guaranteed use, call them explicitly:

```text
/skills use nature-polishing
/skills use nature-data
/skills use nature-figure
```

Then continue the task.

### Recommendation-first

If you want `gemini-2` to choose:

```text
/skills recommend polish my Nature manuscript
/skills recommend Chinese data availability statement for journal submission
/skills recommend publication-ready scientific figure
```

### Natural-language route

For clearly academic prompts, `gemini-2` may route toward them naturally, especially if the request mentions:
- Nature
- manuscript
- academic polishing
- scientific figure
- data availability
- FAIR
- 数据可用性声明

But for important work, explicit `/skills use ...` is still the most reliable path.

## Current Limitations

1. These skills are not meant for general coding tasks.
2. They should not be globally auto-on for everyday engineering prompts.
3. Codex may require a new session before they appear as first-class local skills.
4. `nature-figure` assumes a matplotlib-oriented workflow, not Plotly/Figma/dashboard work.

## Quick Start

### Academic prose

```text
/skills use nature-polishing
Please rewrite my abstract into concise Nature-style English and explain the key changes.
```

### Data statement

```text
/skills use nature-data
请根据我这段中文说明，生成一个 Nature 投稿可用的数据可用性声明，并指出还缺哪些信息。
```

### Scientific figure

```text
/skills use nature-figure
Design a Nature-style 4-panel matplotlib figure for my experiment, including a suggested panel hierarchy and export rules.
```

## Integration Summary

Status:
- shared-fabric source: integrated
- shared-fabric catalog: integrated
- shared-fabric domain route: integrated
- gemini-2 usage path: integrated
- Codex future-session usage: prepared

Best operating stance:
- use as an optional academic specialist pack
- do not treat as a global default for all work
