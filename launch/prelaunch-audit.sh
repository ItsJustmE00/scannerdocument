#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WEBSITE_DIR="$ROOT_DIR/website"

echo "== Prelaunch audit =="

required_files=(
  "$WEBSITE_DIR/index.html"
  "$WEBSITE_DIR/privacy.html"
  "$WEBSITE_DIR/terms.html"
  "$WEBSITE_DIR/support.html"
  "$WEBSITE_DIR/robots.txt"
  "$WEBSITE_DIR/sitemap.xml"
  "$WEBSITE_DIR/favicon.png"
  "$WEBSITE_DIR/og-image.png"
  "$WEBSITE_DIR/indexnow-key.txt"
)

for file in "${required_files[@]}"; do
  if [[ -f "$file" ]]; then
    echo "[OK] $file"
  else
    echo "[MISSING] $file"
  fi
done

PLACEHOLDER_PATTERN="your-domain.com|REPLACE_WITH_GOOGLE_TOKEN|REPLACE_WITH_BING_TOKEN|APPLE_STORE_URL_PLACEHOLDER|PLAY_STORE_URL_PLACEHOLDER"

if rg -n -g '!DEPLOY.md' "$PLACEHOLDER_PATTERN" "$WEBSITE_DIR" >/dev/null; then
  echo "[WARN] Placeholders still present in website files."
  rg -n -g '!DEPLOY.md' "$PLACEHOLDER_PATTERN" "$WEBSITE_DIR"
  echo
  echo "Fix with:"
  echo "  ./launch/release-ready.sh <domain> <apple_url> <play_url> [google_token] [bing_token]"
  echo "  ./launch/configure-domain.sh your-domain.com <google_token> <bing_token>"
  echo "  ./launch/configure-store-links.sh <apple_url> <play_url>"
else
  echo "[OK] No placeholder found in website files."
fi

if [[ $# -ge 1 ]]; then
  DOMAIN="$1"
  echo "\n== Live checks for ${DOMAIN} =="
  curl -sS -I "https://${DOMAIN}" | head -n 1 || true
  curl -sS "https://${DOMAIN}/robots.txt" | head -n 5 || true
  curl -sS "https://${DOMAIN}/sitemap.xml" | head -n 5 || true
  curl -sS "https://${DOMAIN}/indexnow-key.txt" | head -n 2 || true
else
  echo "\nTip: run with domain for live checks"
  echo "Example: ./launch/prelaunch-audit.sh app.example.com"
fi
