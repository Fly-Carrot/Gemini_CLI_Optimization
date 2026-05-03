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
GEMINI_REPO_ROOT="$REPO_ROOT/ref structure/gemini-cli"
LAUNCHER="$REPO_ROOT/gemini-2"
DOCTOR="$REPO_ROOT/scripts/gemini2_doctor.sh"
IMPORTER="$REPO_ROOT/scripts/gemini2_profile_import.mjs"

BUNDLE_PATH=""
GLOBAL_ROOT_OVERRIDE=""
SKIP_NPM_INSTALL=0
SKIP_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      BUNDLE_PATH="${2:-}"
      shift 2
      ;;
    --global-root)
      GLOBAL_ROOT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --skip-npm-install)
      SKIP_NPM_INSTALL=1
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

command -v node >/dev/null 2>&1 || { echo "node is required" >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "python3 is required" >&2; exit 1; }

if [[ ! -d "$GEMINI_REPO_ROOT" ]]; then
  echo "Gemini CLI source repo not found: $GEMINI_REPO_ROOT" >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.gemini"

if [[ "$SKIP_NPM_INSTALL" -eq 0 && ! -d "$GEMINI_REPO_ROOT/node_modules" ]]; then
  echo "[install] npm install"
  (cd "$GEMINI_REPO_ROOT" && npm install)
fi

if [[ "$SKIP_BUILD" -eq 0 ]]; then
  echo "[build] npm run build --workspace @google/gemini-cli-core --workspace @google/gemini-cli"
  (cd "$GEMINI_REPO_ROOT" && npm run build --workspace @google/gemini-cli-core --workspace @google/gemini-cli)
fi

if [[ -n "$BUNDLE_PATH" ]]; then
  echo "[import] applying bundle $BUNDLE_PATH"
  import_args=(node "$IMPORTER" --bundle "$BUNDLE_PATH")
  if [[ -n "$GLOBAL_ROOT_OVERRIDE" ]]; then
    import_args+=(--global-root "$GLOBAL_ROOT_OVERRIDE")
  fi
  "${import_args[@]}"
elif [[ -n "$GLOBAL_ROOT_OVERRIDE" ]]; then
  echo "[import] applying global-root override $GLOBAL_ROOT_OVERRIDE"
  node "$IMPORTER" --global-root "$GLOBAL_ROOT_OVERRIDE"
fi

ln -sfn "$LAUNCHER" "$HOME/.local/bin/gemini-2"
echo "[link] $HOME/.local/bin/gemini-2 -> $LAUNCHER"

"$DOCTOR"
