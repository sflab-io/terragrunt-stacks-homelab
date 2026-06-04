#!/usr/bin/env bash

# Common functions for mise tasks

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Log a command before execution
# Usage: logCommand "command to execute" "output file (optional)" "dry_run flag (optional)"
logCommand() {
  local cmd="$1"
  local dry_run="${2:-false}"

  echo ""
  echo "🚀 Executing..."
  echo "   ${BOLD}Command:${RESET} $cmd"
  echo "   Working dir: $(pwd)"

  echo ""

  if [ "$dry_run" = "true" ]; then
    echo "Dry run mode. Command not executed."
    exit 0
  fi
}
