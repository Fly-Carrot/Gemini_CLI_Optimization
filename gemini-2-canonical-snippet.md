Use /Users/david_chen/Antigravity_Skills/global-agent-fabric as the canonical shared fabric.

Before substantial work, run the shared boot sequence for this workspace using the canonical scripts at:
- /Users/david_chen/Antigravity_Skills/global-agent-fabric/scripts/sync/preflight_check.py
- /Users/david_chen/Antigravity_Skills/global-agent-fabric/scripts/sync/sync_all.py

Do not guess or shorten these paths.
Do not look for preflight_check.py or sync_all.py at the global-root top level.
A boot step is valid only if the canonical scripts actually execute successfully.
If boot fails, say so explicitly and do not claim that shared context was loaded “conceptually” or “in principle”.
Report [BOOT_OK] only after the canonical boot sequence succeeds.

Load global shared context first, then runtime-specific context, then the current project overlay.

For complex tasks, emit exact six-stage phase events via the canonical script:
- /Users/david_chen/Antigravity_Skills/global-agent-fabric/scripts/sync/log_task_phase.py
Use the exact phase keys:
- route
- plan
- review
- dispatch
- execute
- report

Write back through the canonical postflight script:
- /Users/david_chen/Antigravity_Skills/global-agent-fabric/scripts/sync/postflight_sync.py
Report [SYNC_OK] only after canonical write-back succeeds.
If synchronization fails, say so explicitly.

Treat this workspace as project-scoped, not global.

Do not write directly to memory/*.ndjson or sync/*.ndjson; use canonical sync scripts only.
Prefer canonical rich-memory bundle generation over ad-hoc summary-only records.
Route stable reusable learnings to promoted learning, and route detailed process memory / trial-and-error to MemPalace.

Maintain a distilled user-question profile through canonical postflight sync.
For each substantial task, distill the user’s recurring focus points, question patterns, response preferences, reasoning preferences, recurring themes, and frictions/anxieties into a structured user-question-profile payload.
Do not persist raw user prompts by default.
Treat the user-question profile as global-first, and let the current workspace contribute only a project-specific overlay.

Use available MCP tools and local skills when they materially improve accuracy, but keep shared-fabric synchronization on canonical scripts rather than ad-hoc file writes.

A task is not fully synced unless postflight includes a user-question-profile distillation payload for substantial work.
If the active canonical postflight_sync.py does not support user-question-profile distillation, do not claim full sync; say explicitly that user-question-profile write-back is still missing.
