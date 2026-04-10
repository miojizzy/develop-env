#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[10] Install GitHub CLI (gh) and GitLab CLI (glab)"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[10] DRY_RUN: skip"
  exit 0
fi

# Install GitHub CLI (gh)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list
apt-get update
apt-get install -y gh
apt-get clean
rm -rf /var/lib/apt/lists/*

# Install GitLab CLI (glab)
GLAB_VERSION=$(curl -fsSL https://gitlab.com/gitlab-org/cli/-/releases/permalink/latest \
    | grep -oP '(?<=releases/)[^/]+' | head -1 || echo "v1.56.0")
GLAB_VERSION="${GLAB_VERSION:-v1.56.0}"
ARCH=$(dpkg --print-architecture)
curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION#v}_linux_${ARCH}.deb" \
    -o /tmp/glab.deb \
    && dpkg -i /tmp/glab.deb \
    && rm /tmp/glab.deb

echo "[10] GitHub CLI $(gh --version | head -1) installed"
echo "[10] GitLab CLI $(glab --version) installed"
