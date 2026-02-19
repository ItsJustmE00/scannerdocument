param(
  [string]$Domain = "",
  [string]$AppleStoreUrl = "",
  [string]$PlayStoreUrl = "",
  [string]$SupportEmail = ""
)

$ErrorActionPreference = "Stop"
$RootDir = (Resolve-Path "$PSScriptRoot\..").Path
$IndexFile = "$RootDir\website\index.html"
$SupportFile = "$RootDir\website\support.html"
$OutputFile = "$RootDir\launch\store-submission.final.md"

if (-not $Domain -and (Test-Path $IndexFile)) {
  $line = Select-String -Path $IndexFile -Pattern '<link rel="canonical" href="https://([^"]*)/"' | Select-Object -First 1
  if ($line) { $Domain = $line.Matches[0].Groups[1].Value }
}

if (-not $AppleStoreUrl -and (Test-Path $IndexFile)) {
  $line = Select-String -Path $IndexFile -Pattern 'href="([^"]*)"[^>]*>App Store[^<]*<' | Select-Object -First 1
  if ($line) { $AppleStoreUrl = $line.Matches[0].Groups[1].Value }
}

if (-not $PlayStoreUrl -and (Test-Path $IndexFile)) {
  $line = Select-String -Path $IndexFile -Pattern 'href="([^"]*)"[^>]*>Google Play[^<]*<' | Select-Object -First 1
  if ($line) { $PlayStoreUrl = $line.Matches[0].Groups[1].Value }
}

if ($AppleStoreUrl -match '/support\?store=') { $AppleStoreUrl = "" }
if ($PlayStoreUrl -match '/support\?store=') { $PlayStoreUrl = "" }

if (-not $SupportEmail -and (Test-Path $SupportFile)) {
  $line = Select-String -Path $SupportFile -Pattern 'mailto:([^"<>]*)' | Select-Object -First 1
  if ($line) { $SupportEmail = $line.Matches[0].Groups[1].Value }
}

if (-not $Domain) { $Domain = "your-domain.com" }
if (-not $AppleStoreUrl) { $AppleStoreUrl = "PENDING_APPLE_STORE_URL" }
if (-not $PlayStoreUrl) { $PlayStoreUrl = "PENDING_PLAY_STORE_URL" }
if (-not $SupportEmail) { $SupportEmail = "support@your-domain.com" }

$PrivacyUrl = "https://$Domain/privacy"
$SupportUrl = "https://$Domain/support"
$MarketingUrl = "https://$Domain/"
$Today = Get-Date -Format "yyyy-MM-dd"

$content = @"
# Store Submission Final (generated)

Date: $Today

## URLs
- Website: $MarketingUrl
- Privacy: $PrivacyUrl
- Support: $SupportUrl
- Support Email: $SupportEmail
- Apple Store URL: $AppleStoreUrl
- Play Store URL: $PlayStoreUrl

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
$PrivacyUrl

Support URL:
$SupportUrl

Marketing URL:
$MarketingUrl

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
$PrivacyUrl

Support Email:
$SupportEmail

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
- Website live: $MarketingUrl
- Privacy URL: $PrivacyUrl
- Support URL: $SupportUrl
- Terms URL: https://$Domain/terms
- robots.txt: https://$Domain/robots.txt
- sitemap.xml: https://$Domain/sitemap.xml
- IndexNow key: https://$Domain/indexnow-key.txt

## Manual Actions Remaining
- Connect Google Search Console and verify ownership
- Connect Bing Webmaster Tools and verify ownership
- Submit sitemap in GSC and Bing
- Replace store fallback links with real App Store / Play URLs
- Run IndexNow ping after deployment
- Finalize age rating and category in each store console
- Publish launch post and notify email list
"@

Set-Content -Path $OutputFile -Value $content -NoNewline

$warn = $false
foreach ($value in @($Domain, $AppleStoreUrl, $PlayStoreUrl, $SupportEmail)) {
  if ($value -match 'your-domain.com|PLACEHOLDER|PENDING_|/support\?store=') {
    $warn = $true
  }
}

if ($warn) {
  Write-Warning "Generated with placeholders. Fill real domain/store links first."
} else {
  Write-Host "Generated with concrete values."
}

Write-Host "Output: $OutputFile"
