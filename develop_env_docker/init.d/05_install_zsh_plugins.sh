#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[05] Install zsh plugins for root and ${USERNAME}"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[05] DRY_RUN: skip"
  exit 0
fi

GITHUB_MIRRORS=(
  "https://mirror.ghproxy.com/https://github.com"
  "https://gitclone.com/github.com"
  "https://github.com"
)

clone_with_mirror() {
  local repo="$1"
  local dest="$2"
  for mirror in "${GITHUB_MIRRORS[@]}"; do
    echo "[05] Trying clone ${mirror}/${repo}"
    if git clone --depth=1 "${mirror}/${repo}" "${dest}"; then
      echo "[05] Cloned ${repo} from ${mirror}"
      return 0
    fi
    rm -rf "${dest}"
  done
  echo "[05] Failed to clone ${repo} from any mirror"
  return 1
}

for USER_HOME in "/root" "/home/${USERNAME}"; do
  if [ -d "${USER_HOME}" ]; then
    user_name=$(basename "${USER_HOME}")
    plugin_dir="${USER_HOME}/.oh-my-zsh/custom/plugins"
    mkdir -p "${plugin_dir}"
    clone_with_mirror "zsh-users/zsh-autosuggestions" "${plugin_dir}/zsh-autosuggestions"
    clone_with_mirror "zsh-users/zsh-syntax-highlighting" "${plugin_dir}/zsh-syntax-highlighting"
    chown -R "${user_name}:${user_name}" "${USER_HOME}/.oh-my-zsh" || true
  fi
done

echo "[05] zsh plugins installed"
