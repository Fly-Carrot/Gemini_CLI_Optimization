#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="Gemini-2.app"
APP_DIR="$SCRIPT_DIR/$APP_NAME"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
SOURCE_FILE="$SCRIPT_DIR/macos/Gemini2NativeApp/main.m"
PLIST_SOURCE="$SCRIPT_DIR/macos/Gemini2NativeApp/Info.plist"
EXECUTABLE_NAME="Gemini-2"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$PLIST_SOURCE" "$CONTENTS_DIR/Info.plist"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

clang \
  -fobjc-arc \
  -framework Cocoa \
  -lutil \
  "$SOURCE_FILE" \
  -o "$MACOS_DIR/$EXECUTABLE_NAME"

chmod +x "$MACOS_DIR/$EXECUTABLE_NAME"

echo "Built $APP_DIR"
