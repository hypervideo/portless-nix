#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

CURRENT_VERSION=$(grep 'version = "' "$REPO_DIR/default.nix" | head -1 | sed 's/.*version = "\(.*\)";/\1/')
echo "Current version: $CURRENT_VERSION"

LATEST_VERSION=$(curl -sf https://registry.npmjs.org/portless/latest | jq -r '.version')
echo "Latest npm version: $LATEST_VERSION"

if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
  echo "Already up to date."
  exit 0
fi

echo "Updating from $CURRENT_VERSION to $LATEST_VERSION..."

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

TARBALL_URL="https://registry.npmjs.org/portless/-/portless-${LATEST_VERSION}.tgz"
curl -sfL "$TARBALL_URL" -o "$WORK_DIR/portless.tgz"

SRC_HASH=$(nix hash path --mode flat "$WORK_DIR/portless.tgz")
echo "Source hash: $SRC_HASH"

# Newer upstream releases ship a bundled CLI tarball with no runtime npm dependencies.
mkdir -p "$WORK_DIR/package"
tar -xzf "$WORK_DIR/portless.tgz" -C "$WORK_DIR/package" --strip-components=1

RUNTIME_DEP_COUNT=$(jq '(.dependencies // {}) | length' "$WORK_DIR/package/package.json")
if [ "$RUNTIME_DEP_COUNT" -ne 0 ]; then
  echo "Refusing to auto-update: upstream package now has runtime npm dependencies again." >&2
  exit 1
fi

# Update default.nix (use temp file for macOS/Linux portability)
sed "s|version = \"$CURRENT_VERSION\"|version = \"$LATEST_VERSION\"|" "$REPO_DIR/default.nix" \
  | sed "s|hash = \".*\"|hash = \"$SRC_HASH\"|" \
  > "$REPO_DIR/default.nix.tmp"
mv "$REPO_DIR/default.nix.tmp" "$REPO_DIR/default.nix"

echo "Updated portless to $LATEST_VERSION"

# Set GitHub Actions outputs if running in CI
if [ -n "${GITHUB_OUTPUT:-}" ]; then
  echo "VERSION=$LATEST_VERSION" >> "$GITHUB_OUTPUT"
  echo "UPDATED=true" >> "$GITHUB_OUTPUT"
fi
