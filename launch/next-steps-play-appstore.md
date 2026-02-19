# Next Steps: App Store + Play Store + Website Launch

Date: 2026-02-19
Domain: https://scannerdocument.vercel.app

Execution runbook:
- `launch/console-execution-runbook.md`

## 1) App Store / Play Metadata (ready to paste)
- Source: `launch/store-submission.final.md`
- Status: ready, except store URLs still pending.
- Backup metadata source: `launch/app-store-metadata.md`

Set these values when you have store links:
- Apple Store URL -> replace `PENDING_APPLE_STORE_URL`
- Play Store URL -> replace `PENDING_PLAY_STORE_URL`

Regenerate final doc after setting links:
```bash
./launch/build-store-submission.sh scannerdocument.vercel.app "https://apps.apple.com/app/idXXXX" "https://play.google.com/store/apps/details?id=com.example.scannerdocument" support@scannerdocument.vercel.app
```

## 2) Website Validation (production)
Run audit:
```bash
./launch/prelaunch-audit.sh scannerdocument.vercel.app
```

Expected legal routes:
- `/privacy`
- `/terms`
- `/support`

## 3) SEO Manual Tasks
- [ ] Add property in Google Search Console
- [ ] Add property in Bing Webmaster Tools
- [ ] Submit sitemap: `https://scannerdocument.vercel.app/sitemap.xml`
- [ ] Ping IndexNow:
```bash
./website/indexnow-submit.sh scannerdocument.vercel.app
```

## 4) Store Assets
- [ ] Final screenshots exported (benefits-first): see `launch/app-store-screenshots.md`
- [ ] App preview video exported: see `launch/app-preview-video.md`
- [ ] App icon and feature graphic validated per store specs

## 5) Marketing Launch
- [ ] Publish launch post from `launch/social-media-pack.md`
- [ ] Publish Product Hunt listing draft
- [ ] Notify email list (template in `launch/social-media-pack.md`)
- [ ] Activate friends/community plan: `launch/community-outreach.md`

## 6) Legal Final Check
- [x] Privacy policy page live: `/privacy`
- [x] Terms page live: `/terms`
- [x] Support page live: `/support`
- [ ] Final GDPR review against your business context (if targeting EU)

## 7) Fast Release Command
When store URLs are known:
```bash
./launch/release-ready.sh scannerdocument.vercel.app "https://apps.apple.com/app/idXXXX" "https://play.google.com/store/apps/details?id=com.example.scannerdocument" GSC_TOKEN BING_TOKEN
```

Then regenerate final store doc:
```bash
./launch/build-store-submission.sh scannerdocument.vercel.app "https://apps.apple.com/app/idXXXX" "https://play.google.com/store/apps/details?id=com.example.scannerdocument" support@scannerdocument.vercel.app
```
