#!/usr/bin/env bash

# Common functions for mise tasks

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

REQUIRED_ENV_VARS=("TSIG_KEY_SECRET")
OPTIONAL_ENV_VARS=("NETBOX_API_TOKEN" )

# Check that required environment variables are set and non-empty.
# Usage: checkRequiredEnvVars ARRAY_NAME  (pass the array variable name, not its contents)
checkRequiredEnvVars() {
  local _arr_name=$1
  local _var
  local _vals
  local _missing_vars=()

  eval "_vals=(\"\${${_arr_name}[@]}\")"

  for _var in "${_vals[@]}"; do
    if [[ -z "${!_var:-}" ]]; then
      _missing_vars+=("$_var")
    fi
  done

  if [[ ${#_missing_vars[@]} -gt 0 ]]; then
    echo "" >&2
    echo "${RED}[ERROR] Missing environment variables${RESET}" >&2
    echo "" >&2
    for _var in "${_missing_vars[@]}"; do
      echo "  - $_var" >&2
    done

    echo "" >&2
    echo "These variables could not be loaded. This happens when:" >&2
    echo "  • Vault is not yet available (initial infrastructure setup), or" >&2
    echo "  • The secrets could not be read from Vault (check your token and fnox config)." >&2
    echo "" >&2
    echo "If you are currently setting up the infrastructure, set the missing variables manually before retrying:" >&2
    echo "" >&2
    for _var in "${_missing_vars[@]}"; do
      echo "  export $_var=\"...\"" >&2
    done

    echo "" >&2

    exit 1
  fi
}

# Check that optional environment variables are set and non-empty.
# Usage: checkOptionalEnvVars ARRAY_NAME  (pass the array variable name, not its contents)
checkOptionalEnvVars() {
  local _arr_name=$1
  local _var
  local _vals
  local _missing_vars=()

  eval "_vals=(\"\${${_arr_name}[@]}\")"

  for _var in "${_vals[@]}"; do
    if [[ -z "${!_var:-}" ]]; then
      _missing_vars+=("$_var")
    fi
  done

  if [[ ${#_missing_vars[@]} -gt 0 ]]; then
    echo "" >&2
    echo "${YELLOW}[WARNING] Missing environment variables${RESET}" >&2
    echo "" >&2
    for _var in "${_missing_vars[@]}"; do
      echo "  - $_var" >&2
    done

    echo "" >&2
    echo "These variables could not be loaded. This happens when:" >&2
    echo "  • Vault is not yet available (initial infrastructure setup), or" >&2
    echo "  • The secrets could not be read from Vault (check your token and fnox config)." >&2
    echo "" >&2
    echo "If you are currently setting up the infrastructure, set the missing variables manually before retrying:" >&2
    echo "" >&2
    for _var in "${_missing_vars[@]}"; do
      echo "  export $_var=\"...\"" >&2
    done

    echo "" >&2

    sleep 3
  fi
}

# Prompt for environment selection, or use usage_env if already provided.
# Prints the selected environment name to stdout; status message goes to stderr.
selectEnvironment() {
  local env
  if [[ -z "${usage_env:-}" ]]; then
    env=$(printf "staging\nproduction" | gum filter --fuzzy --placeholder "Select an environment:")
  else
    env="${usage_env}"
  fi
  echo "Selected environment: $env" >&2
  echo "$env"
}

# Prompt for stack selection from directories in CWD, or use usage_target if already provided.
# Must be called after cd-ing into the environment directory.
# Prints the selected stack name to stdout.
selectStack() {
  local stack
  if [[ -z "${usage_target:-}" ]]; then
    local stack_dirs=()
    while IFS= read -r -d '' dir; do
      stack_dirs+=("$(basename "$dir")")
    done < <(find "." -mindepth 1 -maxdepth 1 -type d -print0)
    stack=$(printf "%s\n" "${stack_dirs[@]}" | gum filter --fuzzy --placeholder "Select a stack to operate on:")
  else
    stack="${usage_target}"
  fi
  echo "$stack"
}

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
