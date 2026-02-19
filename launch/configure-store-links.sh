#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <apple_store_url> <play_store_url>"
  echo "Example: $0 'https://apps.apple.com/app/id1234567890' 'https://play.google.com/store/apps/details?id=com.example.app'"
  exit 1
fi

APPLE_URL="$1"
PLAY_URL="$2"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$ROOT_DIR/website/index.html"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "Missing file: $INDEX_FILE"
  exit 1
fi

# New website defaults to internal fallback links until store links are known.
# Replace fallback targets and remove "bientot" labels when real URLs are set.
sed -i "s|/support?store=app-store|${APPLE_URL}|g" "$INDEX_FILE"
sed -i "s|/support?store=google-play|${PLAY_URL}|g" "$INDEX_FILE"
sed -i "s|App Store (bientot)|App Store|g" "$INDEX_FILE"
sed -i "s|Google Play (bientot)|Google Play|g" "$INDEX_FILE"

# Backward compatibility for old placeholder-based index versions.
sed -i "s|APPLE_STORE_URL_PLACEHOLDER|${APPLE_URL}|g" "$INDEX_FILE"
sed -i "s|PLAY_STORE_URL_PLACEHOLDER|${PLAY_URL}|g" "$INDEX_FILE"

echo "Store links configured in website/index.html"
echo "Apple: ${APPLE_URL}"
echo "Play: ${PLAY_URL}"
