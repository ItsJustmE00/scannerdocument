param(
  [Parameter(Mandatory=$true)]
  [string]$Domain,

  [Parameter(Mandatory=$true)]
  [string]$AppleStoreUrl,

  [Parameter(Mandatory=$true)]
  [string]$PlayStoreUrl,

  [string]$GoogleToken = "REPLACE_WITH_GOOGLE_TOKEN",
  [string]$BingToken = "REPLACE_WITH_BING_TOKEN"
)

$ErrorActionPreference = "Stop"
$RootDir = (Resolve-Path "$PSScriptRoot\..").Path

function Replace-InFile {
  param(
    [string]$Path,
    [string]$Pattern,
    [string]$Replacement
  )

  if (-not (Test-Path $Path)) {
    return
  }

  $content = Get-Content -Raw -Path $Path
  $content = $content -replace [regex]::Escape($Pattern), $Replacement
  Set-Content -Path $Path -Value $content -NoNewline
}

$files = @(
  "$RootDir\website\index.html",
  "$RootDir\website\privacy.html",
  "$RootDir\website\terms.html",
  "$RootDir\website\support.html",
  "$RootDir\website\DEPLOY.md",
  "$RootDir\website\robots.txt",
  "$RootDir\website\sitemap.xml",
  "$RootDir\launch\app-store-metadata.md",
  "$RootDir\launch\store-submission-template.md",
  "$RootDir\launch\social-media-pack.md",
  "$RootDir\launch\community-outreach.md",
  "$RootDir\launch\seo-setup.md"
)

foreach ($file in $files) {
  Replace-InFile -Path $file -Pattern "https://your-domain.com" -Replacement "https://$Domain"
  Replace-InFile -Path $file -Pattern "your-domain.com" -Replacement $Domain
  Replace-InFile -Path $file -Pattern "REPLACE_WITH_GOOGLE_TOKEN" -Replacement $GoogleToken
  Replace-InFile -Path $file -Pattern "REPLACE_WITH_BING_TOKEN" -Replacement $BingToken
}

$indexFile = "$RootDir\website\index.html"
Replace-InFile -Path $indexFile -Pattern "APPLE_STORE_URL_PLACEHOLDER" -Replacement $AppleStoreUrl
Replace-InFile -Path $indexFile -Pattern "PLAY_STORE_URL_PLACEHOLDER" -Replacement $PlayStoreUrl

$pattern = "your-domain.com|REPLACE_WITH_GOOGLE_TOKEN|REPLACE_WITH_BING_TOKEN|APPLE_STORE_URL_PLACEHOLDER|PLAY_STORE_URL_PLACEHOLDER"
$websiteFiles = Get-ChildItem -Path "$RootDir\website" -File -Recurse | Where-Object { $_.Name -ne "DEPLOY.md" }
$hits = $websiteFiles | Select-String -Pattern $pattern

Write-Host "Release prep complete for $Domain"
Write-Host "Apple URL: $AppleStoreUrl"
Write-Host "Play URL:  $PlayStoreUrl"

if ($hits) {
  Write-Warning "Some placeholders are still present in website files:"
  $hits | ForEach-Object { Write-Host ("{0}:{1}" -f $_.Path, $_.LineNumber) }
} else {
  Write-Host "No placeholders left in website files."
}

Write-Host "Next manual steps:"
Write-Host "1) Deploy website/ in HTTPS"
Write-Host "2) Submit sitemap in GSC/Bing"
Write-Host "3) Run IndexNow: ./website/indexnow-submit.sh $Domain"
