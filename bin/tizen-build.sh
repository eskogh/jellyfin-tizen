#!/usr/bin/env bash
# Build and package the Jellyfin Tizen app
set -euo pipefail

export TIZEN_STUDIO_HOME="${TIZEN_STUDIO_HOME:-/home/jellyfin/tizen-studio}"
export PATH="$TIZEN_STUDIO_HOME/tools/ide/bin:$TIZEN_STUDIO_HOME/tools:$PATH"
export JELLYFIN_WEB_DIR="/jellyfin/jellyfin-web/dist"

# Ensure web assets are built
if [[ ! -d "$JELLYFIN_WEB_DIR" ]] || [[ -z "$(ls -A "$JELLYFIN_WEB_DIR" 2>/dev/null || true)" ]]; then
  echo "Building jellyfin-web..."
  pushd /jellyfin/jellyfin-web >/dev/null
  npm run build
  popd >/dev/null
fi

echo "Installing Tizen app dependencies (if needed)..."
pushd /jellyfin/jellyfin-tizen >/dev/null
(corepack yarn install --immutable || yarn install) >/dev/null

echo "Running tizen build-web..."
tizen build-web \
  -e ".*" \
  -e gulpfile.js \
  -e README.md \
  -e "node_modules/*" \
  -e "package*.json" \
  -e "yarn.lock"

name="${TIZEN_NAME:-Jellyfin}"
password="${TIZEN_PASSWORD:-1234}"

echo "Packaging Jellyfin.wgt (profile: $name)..."
tizen package -t wgt -o . -s "$name" -- .buildResult <<<"$password"
mv -f Jellyfin.wgt /jellyfin/jellyfin-tizen/Jellyfin.wgt
popd >/dev/null

echo "Built: /jellyfin/jellyfin-tizen/Jellyfin.wgt"
