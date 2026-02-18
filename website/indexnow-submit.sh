#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <domain> [key_file]"
  echo "Example: $0 app.example.com ./indexnow-key.txt"
  exit 1
fi

DOMAIN="$1"
KEY_FILE="${2:-$(dirname "$0")/indexnow-key.txt}"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "Key file not found: $KEY_FILE"
  exit 1
fi

KEY="$(cat "$KEY_FILE" | tr -d '[:space:]')"
if [[ -z "$KEY" ]]; then
  echo "IndexNow key is empty"
  exit 1
fi

URLS=(
  "https://${DOMAIN}/"
  "https://${DOMAIN}/privacy.html"
  "https://${DOMAIN}/terms.html"
  "https://${DOMAIN}/support.html"
)

JSON_PAYLOAD=$(cat <<JSON
{
  "host": "${DOMAIN}",
  "key": "${KEY}",
  "keyLocation": "https://${DOMAIN}/indexnow-key.txt",
  "urlList": [
    "${URLS[0]}",
    "${URLS[1]}",
    "${URLS[2]}",
    "${URLS[3]}"
  ]
}
JSON
)

curl -sS -X POST "https://api.indexnow.org/indexnow" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD"

echo

echo "IndexNow ping sent for ${DOMAIN}"
