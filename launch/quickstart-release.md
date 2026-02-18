# Quickstart Release (1 minute)

Date: 2026-02-18

## Option A - PowerShell (Windows)

```powershell
.\launch\release-ready.ps1 -Domain "app.example.com" -AppleStoreUrl "https://apps.apple.com/app/id1234567890" -PlayStoreUrl "https://play.google.com/store/apps/details?id=com.example.scannerdocument" -GoogleToken "GSC_TOKEN" -BingToken "BING_TOKEN"
```

## Option B - Bash (WSL/macOS/Linux)

```bash
./launch/release-ready.sh \
  app.example.com \
  "https://apps.apple.com/app/id1234567890" \
  "https://play.google.com/store/apps/details?id=com.example.scannerdocument" \
  "GSC_TOKEN" \
  "BING_TOKEN"
```

## After command
1. Deploy `website/` to production HTTPS.
2. Submit `https://app.example.com/sitemap.xml` in GSC and Bing.
3. Run IndexNow:

```bash
./website/indexnow-submit.sh app.example.com
```

4. Generate final store copy doc:

```bash
./launch/build-store-submission.sh
```
