#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <domain> <apple_store_url> <play_store_url> [google_token] [bing_token]"
  echo "Example: $0 app.example.com 'https://apps.apple.com/app/id1234567890' 'https://play.google.com/store/apps/details?id=com.example.app' GSC_TOKEN BING_TOKEN"
  exit 1
fi

DOMAIN="$1"
APPLE_URL="$2"
PLAY_URL="$3"
GOOGLE_TOKEN="${4:-REPLACE_WITH_GOOGLE_TOKEN}"
BING_TOKEN="${5:-REPLACE_WITH_BING_TOKEN}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

"$ROOT_DIR/launch/configure-domain.sh" "$DOMAIN" "$GOOGLE_TOKEN" "$BING_TOKEN"
"$ROOT_DIR/launch/configure-store-links.sh" "$APPLE_URL" "$PLAY_URL"
"$ROOT_DIR/launch/prelaunch-audit.sh" "$DOMAIN"

cat <<MSG

Release prep complete.
Next manual steps:
1) Deploy website/ on HTTPS
2) Submit sitemap to Google Search Console and Bing
3) Run: ./website/indexnow-submit.sh $DOMAIN
4) Follow: launch/console-execution-runbook.md
MSG
