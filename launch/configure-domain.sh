#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <domain> [google_token] [bing_token]"
  echo "Example: $0 app.example.com GSC_TOKEN BING_TOKEN"
  exit 1
fi

DOMAIN="$1"
GOOGLE_TOKEN="${2:-REPLACE_WITH_GOOGLE_TOKEN}"
BING_TOKEN="${3:-REPLACE_WITH_BING_TOKEN}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

replace() {
  local file="$1"
  sed -i "s|https://your-domain.com|https://${DOMAIN}|g" "$file"
  sed -i "s|your-domain.com|${DOMAIN}|g" "$file"
  sed -i "s|REPLACE_WITH_GOOGLE_TOKEN|${GOOGLE_TOKEN}|g" "$file"
  sed -i "s|REPLACE_WITH_BING_TOKEN|${BING_TOKEN}|g" "$file"
}

FILES=(
  "$ROOT_DIR/website/index.html"
  "$ROOT_DIR/website/privacy.html"
  "$ROOT_DIR/website/terms.html"
  "$ROOT_DIR/website/support.html"
  "$ROOT_DIR/website/DEPLOY.md"
  "$ROOT_DIR/website/robots.txt"
  "$ROOT_DIR/website/sitemap.xml"
  "$ROOT_DIR/launch/app-store-metadata.md"
  "$ROOT_DIR/launch/store-submission-template.md"
  "$ROOT_DIR/launch/social-media-pack.md"
  "$ROOT_DIR/launch/community-outreach.md"
  "$ROOT_DIR/launch/seo-setup.md"
)

for file in "${FILES[@]}"; do
  if [[ -f "$file" ]]; then
    replace "$file"
  fi
done

echo "Domain configured: ${DOMAIN}"
if [[ "$GOOGLE_TOKEN" == "REPLACE_WITH_GOOGLE_TOKEN" ]]; then
  echo "Google token not provided (left as placeholder)."
fi
if [[ "$BING_TOKEN" == "REPLACE_WITH_BING_TOKEN" ]]; then
  echo "Bing token not provided (left as placeholder)."
fi
