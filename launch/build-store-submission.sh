#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INDEX_FILE="$ROOT_DIR/website/index.html"
SUPPORT_FILE="$ROOT_DIR/website/support.html"
OUTPUT_FILE="$ROOT_DIR/launch/store-submission.final.md"

DOMAIN="${1:-}"
APPLE_URL="${2:-}"
PLAY_URL="${3:-}"
SUPPORT_EMAIL="${4:-}"

if [[ -z "$DOMAIN" && -f "$INDEX_FILE" ]]; then
  DOMAIN="$(sed -n 's|.*<link rel="canonical" href="https://\([^"]*\)/".*|\1|p' "$INDEX_FILE" | head -n 1)"
fi

if [[ -z "$APPLE_URL" && -f "$INDEX_FILE" ]]; then
  APPLE_URL="$(sed -n 's|.*href="\([^"]*\)"[^>]*>App Store[^<]*<.*|\1|p' "$INDEX_FILE" | head -n 1)"
fi

if [[ -z "$PLAY_URL" && -f "$INDEX_FILE" ]]; then
  PLAY_URL="$(sed -n 's|.*href="\([^"]*\)"[^>]*>Google Play[^<]*<.*|\1|p' "$INDEX_FILE" | head -n 1)"
fi

if [[ "$APPLE_URL" == *"/support?store="* ]]; then
  APPLE_URL=""
fi

if [[ "$PLAY_URL" == *"/support?store="* ]]; then
  PLAY_URL=""
fi

if [[ -z "$SUPPORT_EMAIL" && -f "$SUPPORT_FILE" ]]; then
  SUPPORT_EMAIL="$(sed -n 's|.*mailto:\([^"<>]*\).*|\1|p' "$SUPPORT_FILE" | head -n 1)"
fi

TODAY="$(date +%F)"
DOMAIN="${DOMAIN:-your-domain.com}"
APPLE_URL="${APPLE_URL:-PENDING_APPLE_STORE_URL}"
PLAY_URL="${PLAY_URL:-PENDING_PLAY_STORE_URL}"
SUPPORT_EMAIL="${SUPPORT_EMAIL:-support@your-domain.com}"

PRIVACY_URL="https://${DOMAIN}/privacy"
SUPPORT_URL="https://${DOMAIN}/support"
MARKETING_URL="https://${DOMAIN}/"

cat > "$OUTPUT_FILE" <<DOC
# Store Submission Final (generated)

Date: ${TODAY}

## URLs
- Website: ${MARKETING_URL}
- Privacy: ${PRIVACY_URL}
- Support: ${SUPPORT_URL}
- Support Email: ${SUPPORT_EMAIL}
- Apple Store URL: ${APPLE_URL}
- Play Store URL: ${PLAY_URL}

## Apple App Store Connect

App Name:
Scanner Docs Hors Ligne

Subtitle:
FR/AR, PDF, Excel, Sans Cloud

Promotional Text:
Scanne et classe tes documents sans cloud. Exporte en PDF, Excel, TXT et JSON.

Description:
Scanne, classe et exporte tes documents sans internet ni serveur.
Tes factures, recus et contrats restent 100% sur ton telephone.

Scanner OCR Offline transforme tes documents papier en donnees exploitables: texte modifiable, champs detectes (montant, date, reference), recherche rapide et export professionnel.

Pourquoi les utilisateurs l'adorent:
- Scan multi-pages dans une seule session.
- Detection intelligente: facture, recu, contrat.
- Correction manuelle du texte et des donnees avant sauvegarde.
- Export PDF multi-pages, Excel, TXT et JSON.
- Aucune inscription, aucun compte, aucun cloud obligatoire.

Keywords:
scanner,document,facture,recu,contrat,pdf,excel,offline,archive,confidentiel,ocr,francais,arabe

Category:
Primary: Productivity
Secondary: Finance

Age Rating:
4+

Privacy Policy URL:
${PRIVACY_URL}

Support URL:
${SUPPORT_URL}

Marketing URL:
${MARKETING_URL}

## Google Play Console

App Name:
Scanner OCR Offline

Short Description:
Scanner et classer des documents hors ligne, avec export PDF/Excel/TXT/JSON.

Full Description:
Scanne, classe et exporte tes documents sans cloud et sans login.
L'application fonctionne hors ligne pour proteger tes donnees.

Fonctions cles:
- Scan multi-pages.
- Detection et correction du texte.
- Classification facture/recu/contrat.
- Export PDF, Excel, TXT et JSON.

Privacy Policy URL:
${PRIVACY_URL}

Support Email:
${SUPPORT_EMAIL}

## Assets Store (benefits-first)

Screenshots sequence (6):
1. Scanne 1 ou 12 pages en quelques secondes
2. Tes documents restent 100% sur ton telephone
3. Facture, recu ou contrat: classement auto
4. Corrige le texte et les donnees avant sauvegarde
5. Retrouve un document en 2 secondes
6. Exporte en PDF, Excel, TXT ou JSON

App Preview Video (20-30s):
- 0-3s: ouverture app + scan
- 3-8s: capture multi-pages
- 8-13s: texte detecte
- 13-18s: correction des donnees
- 18-23s: classification facture/recu/contrat
- 23-30s: export + promesse offline

## Website / SEO / Legal Status
- Website live: ${MARKETING_URL}
- Privacy URL: ${PRIVACY_URL}
- Support URL: ${SUPPORT_URL}
- Terms URL: https://${DOMAIN}/terms
- robots.txt: https://${DOMAIN}/robots.txt
- sitemap.xml: https://${DOMAIN}/sitemap.xml
- IndexNow key: https://${DOMAIN}/indexnow-key.txt

## Manual Actions Remaining
- Connect Google Search Console and verify ownership
- Connect Bing Webmaster Tools and verify ownership
- Submit sitemap in GSC and Bing
- Replace store fallback links with real App Store / Play URLs
- Run IndexNow ping after deployment
- Finalize age rating and category in each store console
- Publish launch post and notify email list
DOC

warn=0
for value in "$DOMAIN" "$APPLE_URL" "$PLAY_URL" "$SUPPORT_EMAIL"; do
  if [[ "$value" == *"your-domain.com"* ]] || [[ "$value" == *"PLACEHOLDER"* ]] || [[ "$value" == *"/support?store="* ]] || [[ "$value" == PENDING_* ]]; then
    warn=1
  fi
done

if [[ "$warn" -eq 1 ]]; then
  echo "Generated with placeholders. Fill real domain/store links first."
else
  echo "Generated with concrete values."
fi

echo "Output: $OUTPUT_FILE"
