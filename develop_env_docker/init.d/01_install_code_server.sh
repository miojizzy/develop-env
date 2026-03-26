#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[01] Install code-server"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[01] DRY_RUN: skip"
  exit 0
fi

TMPDIR="/tmp"
CODE_SERVER_VERSION="4.112.0"

# Try official installer
if curl -fsSL https://code-server.dev/install.sh -o "${TMPDIR}/code-server-install.sh"; then
  # run the installer script without unsupported flags
  sh "${TMPDIR}/code-server-install.sh"
  echo "[01] Installed code-server via official installer"
else
  echo "[01] Official installer download failed, trying deb download"
  DEB_URL="https://github.com/coder/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_amd64.deb"
  DEB_FILE="${TMPDIR}/code-server_${CODE_SERVER_VERSION}_amd64.deb"
  if curl -fsSL -o "${DEB_FILE}" "${DEB_URL}" && dpkg -i "${DEB_FILE}"; then
    echo "[01] Installed code-server via deb ${DEB_URL}"
  else
    echo "[01] Deb download/install failed, trying apt fallback"
    apt-get update
    apt-get install -y code-server
  fi
fi

if ! command -v code-server >/dev/null 2>&1; then
  echo "[01] code-server command not found after attempts"
  exit 1
fi

echo "[01] code-server is installed"
