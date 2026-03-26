#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[03] Configure git for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[03] DRY_RUN: skip"
  exit 0
fi

GIT_CONFIGS=(
  "http.postBuffer=524288000"
  "http.lowSpeedLimit=0"
  "http.lowSpeedTime=999999"
)

configure_root() {
  for cfg in "${GIT_CONFIGS[@]}"; do
    key=${cfg%%=*}
    value=${cfg#*=}
    git config --global "${key}" "${value}" || { echo "[03] Failed to set ${key} for root"; exit 1; }
  done
}

configure_user() {
  local user="$1"
  for cfg in "${GIT_CONFIGS[@]}"; do
    key=${cfg%%=*}
    value=${cfg#*=}
    su - "${user}" -c "bash -lc 'git config --global \"${key}\" \"${value}\"'" || { echo "[03] Failed to set ${key} for ${user}"; exit 1; }
  done
}

configure_root

if id -u "${USERNAME}" >/dev/null 2>&1; then
  configure_user "${USERNAME}"
else
  echo "[03] User ${USERNAME} does not exist"
  exit 1
fi

echo "[03] Git configured"
