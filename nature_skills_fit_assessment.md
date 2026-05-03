# Nature-Skills Fit Assessment

Date: 2026-05-03

Repository cloned to:
- `/Users/david_chen/Desktop/MCP_Hub/nature-skills`

Repository revision:
- Commit: `2f701331b125b12bf346a30117e03e45ab02e71c`

## Short Answer

Yes, `nature-skills` can be used as a skill source for both the shared framework and `gemini-2`, but it should be integrated as an optional, domain-specific skill pack rather than merged into the default always-on skill surface.

Best fit:
- Shared framework: `yes`
- Gemini CLI / `gemini-2`: `yes, as opt-in skills`
- Default auto-routing for all users: `no`

## What This Repository Actually Is

The repository is a small, well-structured skill pack for academic publishing tasks at Nature-style standard. It currently contains three skills:

1. `nature-figure`
- Publication-ready matplotlib scientific figures.

2. `nature-polishing`
- Nature-style academic prose polishing and restructuring.

3. `nature-data`
- Data Availability statements, repository plans, FAIR checks, and bilingual Chinese/English author alignment.

Each skill already follows a recognizable skill layout:

- `SKILL.md`
- `README.md`
- `references/*.md`

This is very close to the structure already used by Codex-style and shared-fabric skill systems.

## Why It Fits Technically

### 1. The file structure already matches our skill loading model

Our current `gemini-2` shared skill loader resolves a skill directory and then loads `SKILL.md` from it. That is exactly how `nature-skills` is organized.

Examples:
- `/Users/david_chen/Desktop/MCP_Hub/nature-skills/nature-figure/SKILL.md`
- `/Users/david_chen/Desktop/MCP_Hub/nature-skills/nature-polishing/SKILL.md`
- `/Users/david_chen/Desktop/MCP_Hub/nature-skills/nature-data/SKILL.md`

### 2. The frontmatter is usable

The skills already expose:
- `name`
- `description`

That is enough for `gemini-2` to load the skill definition itself.

### 3. The skill content is instruction-first, not tool-first

These skills are mostly:
- domain rules
- editorial heuristics
- structured workflows
- reference loading guidance

That is a good match for a prompt-driven skill system.

### 4. Low execution risk

This repository contains almost no active code. It is mainly content. That makes it much safer than importing unknown shell scripts or Python automation into the shared framework.

## What Does Not Fit Automatically

### 1. It is not indexed for our shared-fabric catalog yet

`gemini-2` does not discover arbitrary folders by magic. It relies on a catalog/index model for recommendation and auto-routing. So these skills are structurally compatible, but not yet registered in:

- shared-fabric catalog
- skill domain map
- source metadata

### 2. It is too domain-specific to be default-global

These skills are very good, but only for a narrow task family:
- scientific figure production
- Nature-style manuscript polishing
- publication data statements

So they should not be added as default high-priority skills for every general coding or product workflow.

### 3. Some wording is Claude-oriented

The repo frames itself as Claude skills. That is not a hard blocker, because the actual format is still markdown skill instructions, but some wording may assume a Claude-centric trigger model and may benefit from light adaptation for `gemini-2`.

### 4. `nature-data` includes agent metadata, but not in our native runtime shape

There is one extra file:
- `/Users/david_chen/Desktop/MCP_Hub/nature-skills/nature-data/agents/openai.yaml`

This is useful as metadata, but it is not directly part of the current `gemini-2` shared-fabric runtime. So it is informative, not plug-and-play.

## Practical Recommendation

Integrate this repository as a new optional source named something like:

- `nature-skills`
- or `academic-writing`

Then expose the three skills individually in the shared skill index:

1. `nature-figure`
2. `nature-polishing`
3. `nature-data`

Recommended source policy:
- source: `community`
- risk: `safe`
- category:
  - `scientific-figures`
  - `academic-writing`
  - `research-data`

## Best Integration Strategy

### For shared-fabric

Recommended: `yes`

How:
1. Add this repo as a separate source, not mixed into the main `awesome-skills` tree by hand.
2. Generate or append catalog entries for the three skills.
3. Add domain routing keywords such as:
- `nature`
- `scientific figure`
- `academic polishing`
- `manuscript`
- `data availability`
- `FAIR`
- `中文润色`
- `数据可用性声明`

4. Keep it opt-in or domain-triggered, not top-priority global.

### For `gemini-2`

Recommended: `yes`

How:
1. Make the three skills discoverable through `/skills search` and `/skills recommend`.
2. Allow auto-routing only when the query is clearly academic or publication-oriented.
3. Do not auto-load these for generic software engineering tasks.

## Suggested Integration Priority

### Highest value

1. `nature-polishing`
- Broadest utility for academic writing.
- Lowest technical friction.

2. `nature-data`
- High practical value for researchers.
- Strong bilingual advantage.

3. `nature-figure`
- Valuable, but narrower because it assumes matplotlib-centric figure workflows.

## Final Judgment

This repository is good enough to be treated as a real skill source.

It is not just a collection of vague prompts. It has:
- clear scope
- modular references
- defined trigger conditions
- workflow-based guidance
- low operational risk

So the answer is:

- Can it become part of the shared framework? `Yes`
- Can it become part of `gemini-2` skills? `Yes`
- Should it be globally auto-on for all tasks? `No`
- Best role: `optional, academic-specialist skill pack`

## Recommended Next Step

If we want to operationalize it, the next concrete step should be:

1. register `nature-skills` as a new shared-fabric source
2. create three catalog entries
3. add a small academic/research domain route
4. test `/skills recommend` against:
- manuscript polishing queries
- Nature figure requests
- data availability / FAIR requests

