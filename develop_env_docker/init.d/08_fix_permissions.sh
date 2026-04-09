#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[08] Fix permissions and shells for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[08] DRY_RUN: skip"
  exit 0
fi

for USER_HOME in "/root" "/home/${USERNAME}"; do
  if [ -d "${USER_HOME}" ]; then
    user_name=$(basename "${USER_HOME}")
    for p in ".oh-my-zsh" ".zshrc" ".nvm" ".bun"; do
      if [ -e "${USER_HOME}/${p}" ]; then
        chown -R "${user_name}:${user_name}" "${USER_HOME}/${p}" || true
      fi
    done
  fi
done

# Set zsh as default shell if available
if command -v zsh >/dev/null 2>&1; then
  chsh -s "$(which zsh)" root || true
  chsh -s "$(which zsh)" "${USERNAME}" || true
fi

echo "[08] Permissions and shells adjusted"
