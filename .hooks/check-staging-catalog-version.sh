#!/usr/bin/env bash
set -euo pipefail

BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || echo "")

if [ "$BRANCH" != "main" ]; then
  exit 0
fi

ENV_FILE="staging/environment.hcl"

if ! grep -qE '^\s*catalog_version\s*=\s*"main"' "$ENV_FILE"; then
  echo "FEHLER: Commits auf 'main' erfordern catalog_version = \"main\" in ${ENV_FILE}"
  echo "Aktueller Wert:"
  grep 'catalog_version' "$ENV_FILE" || echo "  (nicht gefunden)"
  exit 1
fi
