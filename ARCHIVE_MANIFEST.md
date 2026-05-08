# Archive Manifest

## Snapshot purpose

This archive preserves the workspace-level assets around the Gemini-2 system:

- launcher/runtime defaults
- bootstrap and doctor scripts
- macOS shell wrapper source
- workflow notes and integration research

## Core code snapshot

- Gemini-2 fork repository: [Fly-Carrot/gemini-cli](https://github.com/Fly-Carrot/gemini-cli)
- Archived fork commit: [`23314e180`](https://github.com/Fly-Carrot/gemini-cli/commit/23314e180)

## External dependencies expected on a live machine

- canonical shared fabric root:
  - `/Users/david_chen/Antigravity_Skills/global-agent-fabric`
- nature skills local pack:
  - `/Users/david_chen/Desktop/MCP_Hub/nature-skills`

## Restore path

1. Clone this archive repository.
2. Clone the Gemini-2 fork at the commit above into `ref structure/gemini-cli`.
3. Restore or bootstrap the shared-fabric root.
4. Use `scripts/install_gemini2_bootstrap.sh` and `scripts/gemini2_doctor.sh`.
