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
  APPLE_URL="$(sed -n 's|.*href="\([^"]*\)"[^>]*>App Store<.*|\1|p' "$INDEX_FILE" | head -n 1)"
fi

if [[ -z "$PLAY_URL" && -f "$INDEX_FILE" ]]; then
  PLAY_URL="$(sed -n 's|.*href="\([^"]*\)"[^>]*>Google Play<.*|\1|p' "$INDEX_FILE" | head -n 1)"
fi

if [[ -z "$SUPPORT_EMAIL" && -f "$SUPPORT_FILE" ]]; then
  SUPPORT_EMAIL="$(sed -n 's|.*mailto:\([^"<>]*\).*|\1|p' "$SUPPORT_FILE" | head -n 1)"
fi

DOMAIN="${DOMAIN:-your-domain.com}"
APPLE_URL="${APPLE_URL:-APPLE_STORE_URL_PLACEHOLDER}"
PLAY_URL="${PLAY_URL:-PLAY_STORE_URL_PLACEHOLDER}"
SUPPORT_EMAIL="${SUPPORT_EMAIL:-support@your-domain.com}"

PRIVACY_URL="https://${DOMAIN}/privacy.html"
SUPPORT_URL="https://${DOMAIN}/support.html"
MARKETING_URL="https://${DOMAIN}/"

cat > "$OUTPUT_FILE" <<DOC
# Store Submission Final (generated)

Date: 2026-02-18

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
DOC

warn=0
for value in "$DOMAIN" "$APPLE_URL" "$PLAY_URL" "$SUPPORT_EMAIL"; do
  if [[ "$value" == *"your-domain.com"* ]] || [[ "$value" == *"PLACEHOLDER"* ]]; then
    warn=1
  fi
done

if [[ "$warn" -eq 1 ]]; then
  echo "Generated with placeholders. Fill real domain/store links first."
else
  echo "Generated with concrete values."
fi

echo "Output: $OUTPUT_FILE"
