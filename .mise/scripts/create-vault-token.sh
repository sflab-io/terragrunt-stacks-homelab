#!/usr/bin/env bash
# Creates a Vault AppRole token and saves it to ~/.vault-token.
# Credentials are read from ~/.vault-approle (format: role_id=... / secret_id=...)
# or from VAULT_ROLE_ID / VAULT_SECRET_ID environment variables.
#
# Note: The AppRole secret_id must be configured for multiple uses
# (secret_id_num_uses = 0) in Vault, otherwise it expires after first use.

set -euo pipefail

source "$MISE_CONFIG_ROOT/.mise/common.sh"

VAULT_ADDR="${VAULT_ADDR:-https://vault.home.sflab.io:8200}"
APPROLE_FILE="${HOME}/.vault-approle"
TOKEN_FILE="${HOME}/.vault-token"

if [[ -f "${APPROLE_FILE}" ]]; then
  # shellcheck source=/dev/null
  source "${APPROLE_FILE}"
else
  echo "" >&2
  echo "${BOLD}${RED}[vault] AppRole credentials file not found: ${APPROLE_FILE}${RESET}" >&2
  echo "[vault] Create ${APPROLE_FILE} with:" >&2
  echo "  role_id=..." >&2
  echo "  secret_id=..." >&2
  echo ""
  exit 1
fi

ROLE_ID="${VAULT_ROLE_ID:-${role_id:-}}"
SECRET_ID="${VAULT_SECRET_ID:-${secret_id:-}}"

if [[ -z "${ROLE_ID}" || -z "${SECRET_ID}" ]]; then
  echo "[vault] AppRole credentials not found." >&2
  echo "[vault] Create ${APPROLE_FILE} with role_id=... and secret_id=..." >&2
  exit 1
fi

TOKEN=$(VAULT_ADDR="${VAULT_ADDR}" VAULT_SKIP_VERIFY=true vault write -field=token auth/approle/login \
  role_id="${ROLE_ID}" \
  secret_id="${SECRET_ID}" 2>&1) || {
  echo "[vault] Failed to create token: ${TOKEN}" >&2
  exit 1
}

echo "${TOKEN}" >"${TOKEN_FILE}"
chmod 600 "${TOKEN_FILE}"
echo ""
echo "${BOLD}${GREEN}[vault] Token created and saved to ${TOKEN_FILE}${RESET}"
