# Gemini-2 Bootstrap Kit

This kit is the reproducible deployment layer for the customized Gemini-2 runtime.

## Goal

Restore the Gemini-2 stack on a new device with minimal manual work:

- launcher
- merged runtime defaults
- canonical shared-fabric paths
- active Gemini snippet
- curated skill layers
- health checks

## Files

- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/scripts/gemini2_profile_export.mjs`
  - Exports the current deployable runtime profile as a bundle.
- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/scripts/gemini2_profile_import.mjs`
  - Imports a bundle and writes a local runtime overlay plus snippet block.
- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/scripts/install_gemini2_bootstrap.sh`
  - One-click install/build/link/import/doctor wrapper for a new machine.
- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/scripts/gemini2_doctor.sh`
  - Validates launcher, build, canonical scripts, curated skills, and runtime startup.
- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/gemini-2-runtime.local.example.json`
  - Example local overlay config.
- `/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/gemini-2-canonical-snippet.md`
  - Canonical shared-fabric snippet used during import.

## Typical Flow

### 1. Export from the current working machine

```bash
node /Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/scripts/gemini2_profile_export.mjs
```

Default output:

`/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/.gemini2-state/gemini-2-profile.bundle.json`

### 2. Copy the repo and the bundle to the new machine

At minimum, bring:

- this `Gemini_CLI_Optimization` repo
- the canonical shared fabric
- the exported bundle

### 3. Run the installer on the new machine

```bash
/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/scripts/install_gemini2_bootstrap.sh \
  --bundle /path/to/gemini-2-profile.bundle.json
```

What it does:

- installs npm dependencies if missing
- builds Gemini CLI packages
- imports the runtime bundle into `gemini-2-runtime.local.json`
- installs or refreshes the managed Gemini snippet block
- links `~/.local/bin/gemini-2`
- runs the doctor

### 4. Verify manually once

```bash
gemini-2 --version
```

Then start a real session and confirm `[BOOT_OK]` appears in a normal workspace.

## Manual Notes

- OAuth / Google login state is still device-local. Re-auth may be needed.
- External MCP/API credentials stored outside this repo still need to exist on the new machine.
- The installer is designed to avoid rewriting the entire `~/.gemini/GEMINI.md` file. It manages only a clearly delimited snippet block.

## Design Choice

The repo keeps a stable base config in `gemini-2-runtime.json` and writes machine-specific differences into `gemini-2-runtime.local.json`.

That means:

- shared defaults stay versioned
- new devices only need a small local overlay
- future upgrades do not require copying the entire runtime config
