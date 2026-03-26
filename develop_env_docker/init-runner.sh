#!/bin/bash
set -euo pipefail

# Usage: $0 <username> [step_filter]
#   step_filter: "all" (default) | single step prefix e.g. "01" | comma-separated "01,02,05"
# DRY_RUN=1 env var: each called script will print a fake success and exit immediately.

USERNAME="${1:?Usage: $0 <username> [step_filter]}"
STEP_FILTER="${2:-all}"
SCRIPTS_DIR="/tmp/init.d"

if [ ! -d "$SCRIPTS_DIR" ]; then
  echo "Init scripts directory $SCRIPTS_DIR not found"
  exit 1
fi

run_script() {
  local script="$1"
  echo ">>> Running $(basename "$script")"
  chmod +x "$script"
  "$script" "${USERNAME}"
  echo "<<< Completed $(basename "$script")"
}

echo "Init runner: user=${USERNAME} filter=${STEP_FILTER} dry_run=${DRY_RUN:-0}"

if [ "$STEP_FILTER" = "all" ]; then
  for script in $(ls -1 "$SCRIPTS_DIR"/*.sh 2>/dev/null | sort); do
    run_script "$script"
  done
else
  IFS=',' read -ra steps <<< "$STEP_FILTER"
  for step in "${steps[@]}"; do
    step="${step// /}"
    matches=( "$SCRIPTS_DIR"/${step}_*.sh )
    if [ "${#matches[@]}" -eq 0 ] || [ ! -f "${matches[0]}" ]; then
      echo "No script found for step '${step}' in $SCRIPTS_DIR"
      exit 1
    fi
    run_script "${matches[0]}"
  done
fi

echo "Done: filter=${STEP_FILTER}"
