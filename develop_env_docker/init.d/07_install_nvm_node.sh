#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[07] Install nvm and Node.js for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[07] DRY_RUN: skip"
  exit 0
fi

NVM_VERSION="v0.40.3"
NODE_VERSION="24"

install_nvm_for() {
  local user="$1"
  local home="$2"
  local nvm_dir="${home}/.nvm"
  local script="/tmp/nvm_install_${user}.sh"
  local installed=0

  # Try installer script
  if curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" -o "${script}"; then
    if [ "${user}" = "root" ]; then
      bash "${script}" || true
    else
      su - "${user}" -c "bash -lc 'bash ${script}'" || true
    fi
  fi

  # Fallback: git clone
  if [ ! -s "${nvm_dir}/nvm.sh" ]; then
    echo "[07] Installer did not produce nvm; trying git clone for ${user}"
    if [ "${user}" = "root" ]; then
      git clone https://github.com/nvm-sh/nvm.git "${nvm_dir}" \
        || git clone https://mirror.ghproxy.com/https://github.com/nvm-sh/nvm.git "${nvm_dir}"
      cd "${nvm_dir}" && git checkout "${NVM_VERSION}" || true
    else
      su - "${user}" -c "git clone https://github.com/nvm-sh/nvm.git '${nvm_dir}' || git clone https://mirror.ghproxy.com/https://github.com/nvm-sh/nvm.git '${nvm_dir}'" || true
      su - "${user}" -c "cd '${nvm_dir}' && git checkout '${NVM_VERSION}'" || true
    fi
  fi

  # Verify and use nvm
  if [ "${user}" = "root" ]; then
    export NVM_DIR="${nvm_dir}"
    if [ -s "${NVM_DIR}/nvm.sh" ]; then
      # shellcheck disable=SC1090
      source "${NVM_DIR}/nvm.sh"
      nvm install "${NODE_VERSION}"
      nvm alias default "${NODE_VERSION}"
      npm install -g @hsupu/copilot-api || true
      installed=1
    fi
  else
    su - "${user}" -c "bash -lc 'export NVM_DIR=\"${nvm_dir}\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && source \"\$NVM_DIR/nvm.sh\" && nvm install ${NODE_VERSION} && nvm alias default ${NODE_VERSION} && npm install -g @hsupu/copilot-api'" || true
    # Check presence
    if su - "${user}" -c "bash -lc '[ -s \"${nvm_dir}/nvm.sh\" ] && echo ok'" | grep -q ok; then
      installed=1
    fi
  fi

  if [ "${installed}" -ne 1 ]; then
    echo "[07] Failed to install nvm/node for ${user}"
    exit 1
  fi
}

install_nvm_for root /root

if id -u "${USERNAME}" >/dev/null 2>&1; then
  install_nvm_for "${USERNAME}" "/home/${USERNAME}"
else
  echo "[07] User ${USERNAME} not found"
  exit 1
fi

echo "[07] nvm and node installed"
