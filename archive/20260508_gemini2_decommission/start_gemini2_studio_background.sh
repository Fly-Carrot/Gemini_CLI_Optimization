#!/usr/bin/env bash
set -euo pipefail

SOURCE_PATH="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE_PATH" ]]; do
  SOURCE_DIR="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
  SOURCE_PATH="$(readlink "$SOURCE_PATH")"
  [[ "$SOURCE_PATH" != /* ]] && SOURCE_PATH="$SOURCE_DIR/$SOURCE_PATH"
done

PROJECT_ROOT="$(cd "$(dirname "$SOURCE_PATH")" && pwd)"
PORT="${GEMINI2_STUDIO_PORT:-43137}"
LOG_DIR="$PROJECT_ROOT/.gemini2-studio"
LOG_FILE="$LOG_DIR/studio.log"
PID_FILE="$LOG_DIR/studio.pid"

mkdir -p "$LOG_DIR"

is_running() {
  local pid=""
  if [[ -f "$PID_FILE" ]]; then
    pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  fi

  if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
    return 0
  fi

  if lsof -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
    return 0
  fi

  return 1
}

if ! is_running; then
  nohup "$PROJECT_ROOT/run_gemini2_studio.sh" >"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
fi

for _ in {1..60}; do
  if curl -fsS "http://127.0.0.1:$PORT" >/dev/null 2>&1; then
    exit 0
  fi
  sleep 1
done

echo "Gemini-2 Studio did not become ready on port $PORT. Check $LOG_FILE." >&2
exit 1
