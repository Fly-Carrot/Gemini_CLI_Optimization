#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_ROOT="/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization"
SOURCE_SLUG="gemini-cli"
SOURCE_HISTORY_DIR="$HOME/.gemini/history/$SOURCE_SLUG"
SOURCE_TMP_DIR="$HOME/.gemini/tmp/$SOURCE_SLUG"
TARGET_PROJECT_ROOT="${1:-$WORKSPACE_ROOT}"

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

TARGET_SLUG="$(basename "$TARGET_PROJECT_ROOT" | awk '{print tolower($0)}' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')"
if [[ -z "$TARGET_SLUG" ]]; then
  TARGET_SLUG="project"
fi

TARGET_HISTORY_DIR="$HOME/.gemini/history/$TARGET_SLUG"
TARGET_TMP_DIR="$HOME/.gemini/tmp/$TARGET_SLUG"

echo "Gemini-2 history migration dry-run"
echo
echo "Source project root:"
if [[ -f "$SOURCE_HISTORY_DIR/.project_root" ]]; then
  cat "$SOURCE_HISTORY_DIR/.project_root"
else
  echo "(missing)"
fi
echo
echo "Target project root: $TARGET_PROJECT_ROOT"
echo "Predicted target slug: $TARGET_SLUG"
echo
echo "Source history dir: $SOURCE_HISTORY_DIR"
echo "Source tmp dir:     $SOURCE_TMP_DIR"
echo "Target history dir: $TARGET_HISTORY_DIR"
echo "Target tmp dir:     $TARGET_TMP_DIR"
echo
echo "Files that would be reviewed for copy:"
find "$SOURCE_HISTORY_DIR" "$SOURCE_TMP_DIR" -type f 2>/dev/null | sort || true
echo
echo "Suggested next copy-first commands:"
echo "mkdir -p \"$TARGET_HISTORY_DIR\" \"$TARGET_TMP_DIR\""
echo "cp -R \"$SOURCE_HISTORY_DIR\"/. \"$TARGET_HISTORY_DIR\"/"
echo "cp -R \"$SOURCE_TMP_DIR\"/. \"$TARGET_TMP_DIR\"/"
echo
echo "Important:"
echo "- This script does not modify anything."
echo "- Validate with official gemini after copying before deleting old source buckets."
