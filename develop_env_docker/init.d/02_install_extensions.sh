#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[02] Install code-server extensions for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[02] DRY_RUN: skip"
  exit 0
fi

EXTENSIONS=(
  "cnbcool.cnb-welcome"
  "tencent-cloud.coding-copilot"
  "ms-vscode.cmake-tools"
)

install_for_user() {
  local user="$1"
  for ext in "${EXTENSIONS[@]}"; do
    echo "[02] Installing ${ext} for ${user}"
    tries=0
    until [ "$tries" -ge 5 ]; do
      if [ "$user" = "root" ]; then
        code-server --install-extension "${ext}" && break
      else
        su - "${user}" -c "bash -lc 'code-server --install-extension ${ext}'" && break
      fi
      tries=$((tries+1))
      echo "[02] Retry ${tries} for ${ext} (user=${user})"
      sleep 2
    done
    if [ "$tries" -ge 5 ]; then
      echo "[02] Failed to install extension ${ext} for ${user} after retries"
      exit 1
    fi
  done
}

if ! command -v code-server >/dev/null 2>&1; then
  echo "[02] code-server not available; cannot install extensions"
  exit 1
fi

install_for_user root

if id -u "${USERNAME}" >/dev/null 2>&1; then
  install_for_user "${USERNAME}"
else
  echo "[02] User ${USERNAME} not found"
  exit 1
fi

echo "[02] Extensions installed"
