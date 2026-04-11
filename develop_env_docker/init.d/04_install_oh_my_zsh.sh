#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[04] Install Oh My Zsh for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[04] DRY_RUN: skip"
  exit 0
fi

OMZ_URLS=(
  "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
  "https://ghproxy.com/https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
)

install_omz_for() {
  local user="$1"
  local home="$2"
  local script="/tmp/omz_install_${user}.sh"
  local installed=0

  for url in "${OMZ_URLS[@]}"; do
    echo "[04] Trying OMZ installer ${url} for ${user}"
    if curl -fsSL "${url}" -o "${script}"; then
      if [ "${user}" = "root" ]; then
        bash "${script}" --unattended && installed=1 && break
      else
        su - "${user}" -c "bash -lc 'bash ${script} --unattended'" && installed=1 && break
      fi
    else
      echo "[04] Download failed from ${url}"
    fi
  done

  if [ "${installed}" -eq 0 ]; then
    echo "[04] Installer failed, trying git clone fallback for ${user}"
    if [ "${user}" = "root" ]; then
      git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "${home}/.oh-my-zsh" \
        || git clone --depth=1 https://mirror.ghproxy.com/https://github.com/ohmyzsh/ohmyzsh.git "${home}/.oh-my-zsh"
      cp "${home}/.oh-my-zsh/templates/zshrc.zsh-template" "${home}/.zshrc" || true
      installed=1
    else
      local omz_dest="${home}/.oh-my-zsh"
      su - "${user}" -c "git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git '${omz_dest}' || git clone --depth=1 https://mirror.ghproxy.com/https://github.com/ohmyzsh/ohmyzsh.git '${omz_dest}'" || true
      su - "${user}" -c "[ -f '${omz_dest}/templates/zshrc.zsh-template' ] && cp '${omz_dest}/templates/zshrc.zsh-template' '${home}/.zshrc'" || true
      if [ -d "${home}/.oh-my-zsh" ]; then
        installed=1
      fi
    fi
  fi

  if [ "${installed}" -eq 0 ]; then
    echo "[04] Failed to install Oh My Zsh for ${user}"
    exit 1
  fi
}

# root and user in parallel
install_omz_for root /root &
PID_ROOT=$!

if id -u "${USERNAME}" >/dev/null 2>&1; then
  install_omz_for "${USERNAME}" "/home/${USERNAME}" &
  PID_USER=$!
else
  echo "[04] User ${USERNAME} not found"
  exit 1
fi

wait $PID_ROOT
wait $PID_USER

echo "[04] Oh My Zsh installed"
