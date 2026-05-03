#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="/Users/david_chen/Desktop/MCP_Hub/Gemini_CLI_Optimization/ref structure/gemini-cli"

cd "$REPO_ROOT"
exec node "packages/cli/dist/index.js" "$@"
