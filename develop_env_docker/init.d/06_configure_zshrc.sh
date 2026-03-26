#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[06] Configure .zshrc for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[06] DRY_RUN: skip"
  exit 0
fi

prepend_block=$'setopt NULL_GLOB 2>/dev/null
source /etc/profile
unsetopt NULL_GLOB 2>/dev/null
if command -v docker > /dev/null; then
    docker completion zsh > ~/.oh-my-zsh/completions/_docker
fi
'

for USER_HOME in "/root" "/home/${USERNAME}"; do
  if [ -d "${USER_HOME}" ]; then
    user_name=$(basename "${USER_HOME}")
    zshrc="${USER_HOME}/.zshrc"
    mkdir -p "${USER_HOME}/.oh-my-zsh/completions"
    # Add NO_AUTO_REMOVE_SLASH if not present
    if ! grep -q "NO_AUTO_REMOVE_SLASH" "${zshrc}" 2>/dev/null; then
      echo 'setopt NO_AUTO_REMOVE_SLASH' >> "${zshrc}"
    fi
    # Prepend the block if not already present
    if ! grep -q "setopt NULL_GLOB" "${zshrc}" 2>/dev/null; then
      tmpfile=$(mktemp)
      printf "%s" "${prepend_block}" > "${tmpfile}"
      cat "${zshrc}" >> "${tmpfile}"
      mv "${tmpfile}" "${zshrc}"
    fi
    chown "${user_name}:${user_name}" "${zshrc}" || true
  fi
done

echo "[06] .zshrc configured"
