#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[09] Install Bun for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[09] DRY_RUN: skip"
  exit 0
fi

BUN_INSTALL_SCRIPT="https://bun.sh/install"

install_bun_for() {
  local user="$1"
  local home="$2"
  local bun_dir="${home}/.bun"

  echo "[09] Installing Bun for ${user} (home: ${home})"

  local script="/tmp/bun_install_${user}.sh"

  # Download installer
  if ! curl -fsSL "${BUN_INSTALL_SCRIPT}" -o "${script}"; then
    echo "[09] WARNING: Failed to download Bun installer for ${user}, skipping"
    return 0
  fi

  if [ "${user}" = "root" ]; then
    HOME="${home}" bash "${script}" || true
  else
    su - "${user}" -c "HOME='${home}' bash '${script}'" || true
  fi

  rm -f "${script}"

  # Symlink to /usr/local/bin so bun is on PATH for all users
  if [ -x "${bun_dir}/bin/bun" ]; then
    ln -sf "${bun_dir}/bin/bun" /usr/local/bin/bun
    echo "[09] Bun installed for ${user}: $(${bun_dir}/bin/bun --version)"
  else
    echo "[09] WARNING: Bun binary not found at ${bun_dir}/bin/bun for ${user}"
  fi
}

install_bun_for "root" "/root"
install_bun_for "${USERNAME}" "/home/${USERNAME}"

echo "[09] Bun installation complete"
