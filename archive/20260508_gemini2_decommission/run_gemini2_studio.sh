#!/usr/bin/env bash
set -euo pipefail

SOURCE_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE_PATH" ]]; do
  SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
  SOURCE_PATH="$(readlink "$SOURCE_PATH")"
  [[ "$SOURCE_PATH" != /* ]] && SOURCE_PATH="$SOURCE_DIR/$SOURCE_PATH"
done

SCRIPT_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
REPO_ROOT="$SCRIPT_DIR/ref structure/gemini-cli"
RUNTIME_CONFIG_DEFAULT="$SCRIPT_DIR/gemini-2-runtime.json"
RUNTIME_CONFIG_HELPER="$SCRIPT_DIR/scripts/read_gemini2_runtime_field.mjs"

export GEMINI2_RUNTIME_CONFIG_PATH="${GEMINI2_RUNTIME_CONFIG_PATH:-$RUNTIME_CONFIG_DEFAULT}"

read_runtime_config_field() {
  local field="$1"
  if [[ -f "$GEMINI2_RUNTIME_CONFIG_PATH" && -f "$RUNTIME_CONFIG_HELPER" ]]; then
    node "$RUNTIME_CONFIG_HELPER" "$GEMINI2_RUNTIME_CONFIG_PATH" "$field" 2>/dev/null || true
  fi
}

runtime_fabric_root="$(read_runtime_config_field sharedFabricRoot)"
runtime_system_settings_path="$(read_runtime_config_field systemSettingsPath)"
runtime_default_model="$(read_runtime_config_field defaults.model)"
runtime_default_effort="$(read_runtime_config_field defaults.effort)"

export GEMINI2_SHARED_FABRIC_ROOT="${GEMINI2_SHARED_FABRIC_ROOT:-${runtime_fabric_root:-$HOME/Antigravity_Skills/global-agent-fabric}}"
export GEMINI2_SHARED_FABRIC_WORKSPACE="${GEMINI2_SHARED_FABRIC_WORKSPACE:-$SCRIPT_DIR}"
export GEMINI_CLI_SYSTEM_SETTINGS_PATH="${GEMINI_CLI_SYSTEM_SETTINGS_PATH:-${runtime_system_settings_path:-$SCRIPT_DIR/gemini-2-system-settings.json}}"
export GEMINI2_DEFAULT_MODEL="${GEMINI2_DEFAULT_MODEL:-${runtime_default_model:-pro}}"
export GEMINI2_DEFAULT_EFFORT="${GEMINI2_DEFAULT_EFFORT:-${runtime_default_effort:-high}}"
export GEMINI2_STUDIO_PORT="${GEMINI2_STUDIO_PORT:-43137}"

cd "$REPO_ROOT"
npm run build --workspace @google/gemini-cli-desktop-shell
npm run start --workspace @google/gemini-cli-desktop-shell
