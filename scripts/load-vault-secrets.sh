#!/usr/bin/env bash
# Sourced by mise [env] _.source on directory entry.
# Loads Vault secrets as env vars via Teller.

export VAULT_ADDR="${VAULT_ADDR:-https://vault.home.sflab.io:8200}"

# Resolve token: env var → cached file → fresh AppRole login
if [[ -z "${VAULT_TOKEN:-}" ]]; then
  if [[ -f "${HOME}/.vault-token" ]]; then
    VAULT_TOKEN=$(cat "${HOME}/.vault-token")
  elif [[ -n "${VAULT_ROLE_ID:-}" ]]; then
    mise run vault:login
    VAULT_TOKEN=$(cat "${HOME}/.vault-token")
  else
    return 0
  fi
  export VAULT_TOKEN
fi

eval "$(teller sh 2>/dev/null | grep "^export")" || true
