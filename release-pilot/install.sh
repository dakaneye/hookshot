#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="${1:-latest}"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *) echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

if [[ "$VERSION" != "latest" ]]; then
  if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    printf 'Error: unexpected version format: %s\n' "$VERSION" >&2
    exit 1
  fi
fi

AUTH_HEADER=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH_HEADER=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

if [[ "$VERSION" == "latest" ]]; then
  VERSION="$(curl -fsSL "${AUTH_HEADER[@]}" https://api.github.com/repos/dakaneye/release-pilot/releases/latest | grep '"tag_name"' | head -1 | cut -d'"' -f4)"
  if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
    printf 'Error: unexpected version format: %s\n' "$VERSION" >&2
    exit 1
  fi
fi

URL="https://github.com/dakaneye/release-pilot/releases/download/${VERSION}/release-pilot_${VERSION#v}_${OS}_${ARCH}.tar.gz"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

curl -fsSL "${AUTH_HEADER[@]}" "$URL" -o "$WORK_DIR/release-pilot.tar.gz"
tar -xzf "$WORK_DIR/release-pilot.tar.gz" -C "$WORK_DIR"
install -m 755 "$WORK_DIR/release-pilot" /usr/local/bin/release-pilot

echo "release-pilot ${VERSION} installed"
