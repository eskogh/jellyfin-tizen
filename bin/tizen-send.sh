#!/usr/bin/env bash
# Install Jellyfin.wgt to a Tizen TV in developer mode
set -euo pipefail

export TIZEN_STUDIO_HOME="${TIZEN_STUDIO_HOME:-/home/jellyfin/tizen-studio}"
export PATH="$TIZEN_STUDIO_HOME/tools/ide/bin:$TIZEN_STUDIO_HOME/tools:$PATH"

ip="${TIZEN_IP:-}"
if [[ -z "$ip" ]]; then
  read -r -p "Enter IP of Samsung TV (Developer Mode enabled): " ip
fi

wgt="/jellyfin/jellyfin-tizen/Jellyfin.wgt"
if [[ ! -f "$wgt" ]]; then
  echo "Widget not found at $wgt. Build first (tizen-jellyfin build)." >&2
  exit 1
fi

echo "Listing devices..."
"$TIZEN_STUDIO_HOME/tools/sdb" devices || true

echo "Connecting to $ip..."
"$TIZEN_STUDIO_HOME/tools/sdb" connect "$ip"

echo "Resolving target id..."
tvid=$("$TIZEN_STUDIO_HOME/tools/sdb" devices | awk -v ip="$ip" '$0 ~ ip {print $NF}')
if [[ -z "$tvid" ]]; then
  echo "Could not resolve target id for $ip" >&2
  exit 1
fi

echo "Installing to target '$tvid'..."
tizen install -n "$wgt" -t "$tvid"
echo "Done."
