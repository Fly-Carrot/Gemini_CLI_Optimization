#!/usr/bin/env bash
set -euo pipefail

SOURCE_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE_PATH" ]]; do
  SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
  SOURCE_PATH="$(readlink "$SOURCE_PATH")"
  [[ "$SOURCE_PATH" != /* ]] && SOURCE_PATH="$SOURCE_DIR/$SOURCE_PATH"
done

SCRIPT_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LAUNCHER="$REPO_ROOT/gemini-2"
CLI_ENTRY="$REPO_ROOT/ref structure/gemini-cli/packages/cli/dist/index.js"
BASE_CONFIG="$REPO_ROOT/gemini-2-runtime.json"
LOCAL_CONFIG="${GEMINI2_RUNTIME_CONFIG_LOCAL_PATH:-$REPO_ROOT/gemini-2-runtime.local.json}"
HELPER="$REPO_ROOT/scripts/read_gemini2_runtime_field.mjs"
DEFAULT_GLOBAL_ROOT="$HOME/Antigravity_Skills/global-agent-fabric"

failures=()

check_file() {
  local target="$1"
  local label="$2"
  if [[ -e "$target" ]]; then
    echo "[ok] $label -> $target"
  else
    echo "[missing] $label -> $target"
    failures+=("$label")
  fi
}

read_config_field() {
  local field="$1"
  local args=()
  [[ -f "$BASE_CONFIG" ]] && args+=("$BASE_CONFIG")
  [[ -f "$LOCAL_CONFIG" ]] && args+=("$LOCAL_CONFIG")
  if [[ ${#args[@]} -gt 0 ]]; then
    node "$HELPER" "${args[@]}" "$field" 2>/dev/null || true
  fi
}

check_file "$LAUNCHER" "gemini-2 launcher"
check_file "$CLI_ENTRY" "built CLI entry"
check_file "$BASE_CONFIG" "base runtime config"
check_file "$HELPER" "runtime config helper"
check_file "$REPO_ROOT/gemini-2-canonical-snippet.md" "canonical snippet source"

resolved_global_root="$(read_config_field sharedFabricRoot)"
if [[ -z "$resolved_global_root" ]]; then
  resolved_global_root="$DEFAULT_GLOBAL_ROOT"
fi

check_file "$resolved_global_root/scripts/sync/preflight_check.py" "canonical preflight script"
check_file "$resolved_global_root/scripts/sync/sync_all.py" "canonical sync script"
check_file "$resolved_global_root/scripts/sync/log_task_phase.py" "canonical phase logger"
check_file "$resolved_global_root/scripts/sync/postflight_sync.py" "canonical postflight script"
check_file "$resolved_global_root/skills/curated/current-workflow" "curated current-workflow skill layer"
check_file "$resolved_global_root/skills/curated/top50-current-workflow" "curated top50 skill layer"
check_file "$resolved_global_root/skills/awesome-skills/skills_index.json" "awesome-skills index"

if [[ -L "$HOME/.local/bin/gemini-2" || -x "$HOME/.local/bin/gemini-2" ]]; then
  echo "[ok] user launcher link -> $HOME/.local/bin/gemini-2"
else
  echo "[missing] user launcher link -> $HOME/.local/bin/gemini-2"
  failures+=("user launcher link")
fi

if "$LAUNCHER" --version >/dev/null 2>&1; then
  echo "[ok] gemini-2 --version"
else
  echo "[failed] gemini-2 --version"
  failures+=("gemini-2 --version")
fi

if [[ ${#failures[@]} -gt 0 ]]; then
  echo
  echo "doctor status: failed"
  printf 'failed checks: %s\n' "${failures[*]}"
  exit 1
fi

echo
echo "doctor status: healthy"
