#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[10] Install GitHub CLI (gh) and GitLab CLI (glab)"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[10] DRY_RUN: skip"
  exit 0
fi

# Install GitHub CLI (gh) and GitLab CLI (glab) in parallel
# Pin versions to avoid slow remote version queries
GH_VERSION="v2.89.0"
GLAB_VERSION="v1.56.0"
ARCH=$(dpkg --print-architecture)

# Download both deb packages in parallel to avoid slow apt source from cli.github.com
curl -fsSL "https://github.com/cli/cli/releases/download/${GH_VERSION}/gh_${GH_VERSION#v}_linux_${ARCH}.deb" \
    -o /tmp/gh.deb &
PID_GH=$!

curl -fsSL "https://gitlab.com/gitlab-org/cli/-/releases/${GLAB_VERSION}/downloads/glab_${GLAB_VERSION#v}_linux_${ARCH}.deb" \
    -o /tmp/glab.deb &
PID_GLAB=$!

# Wait for both downloads to complete
wait $PID_GH
wait $PID_GLAB

# Install both from pre-downloaded deb packages
dpkg -i /tmp/gh.deb   && rm /tmp/gh.deb
dpkg -i /tmp/glab.deb && rm /tmp/glab.deb

echo "[10] GitHub CLI $(gh --version | head -1) installed"
echo "[10] GitLab CLI $(glab --version) installed"
