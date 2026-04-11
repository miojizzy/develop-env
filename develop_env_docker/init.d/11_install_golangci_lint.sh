#!/bin/bash
set -euo pipefail

USERNAME="$1"
echo "[11] Install golangci-lint"

DRY_RUN="${DRY_RUN:-0}"
if [ "$DRY_RUN" = "1" ]; then
  echo "[11] DRY_RUN: skip"
  exit 0
fi

GOLANGCI_LINT_VERSION="v2.1.6"
ARCH=$(uname -m)
case "${ARCH}" in
  x86_64)  ARCH_NAME="amd64" ;;
  aarch64) ARCH_NAME="arm64" ;;
  *)       ARCH_NAME="${ARCH}" ;;
esac

TARBALL="/tmp/golangci-lint.tar.gz"

curl -fsSL \
  "https://github.com/golangci/golangci-lint/releases/download/${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION#v}-linux-${ARCH_NAME}.tar.gz" \
  -o "${TARBALL}"

tar -xzf "${TARBALL}" \
  --strip-components=1 \
  -C /usr/local/bin \
  "golangci-lint-${GOLANGCI_LINT_VERSION#v}-linux-${ARCH_NAME}/golangci-lint"

rm "${TARBALL}"

echo "[11] golangci-lint $(golangci-lint --version) installed"
