# Launch Checklist (etat reel)

Date: 2026-02-19
Domain: https://scannerdocument.vercel.app

## Blocages actuels a fermer en priorite
- [ ] Remplacer `REPLACE_WITH_GOOGLE_TOKEN` dans `website/index.html`
- [ ] Remplacer `REPLACE_WITH_BING_TOKEN` dans `website/index.html`
- [ ] Remplacer les fallback store links (`/support?store=...`) par les vraies URLs App Store + Play
- [ ] Re-pousser et redeployer pour activer les liens definitifs

## App Store Stuff
- [x] App title with keywords (dans `launch/app-store-metadata.md`)
- [x] Subtitle renseigne (pas vide)
- [x] App description avec hook dans les 2 premieres lignes
- [x] Keywords researches et ajoutes
- [x] Plan screenshots axe benefices (dans `launch/app-store-screenshots.md`)
- [x] Script App Preview Video (dans `launch/app-preview-video.md`)
- [x] Privacy policy URL renseignee: `https://scannerdocument.vercel.app/privacy`
- [x] Support URL renseignee: `https://scannerdocument.vercel.app/support`
- [x] App category proposee (Productivity / Finance)
- [x] Age rating propose (4+)
- [ ] Saisie finale dans App Store Connect (action manuelle)
- [ ] Saisie finale dans Google Play Console (action manuelle)

## Website Stuff
- [x] Landing page live
- [x] Open Graph tags en place (`og:title`, `og:description`, `og:image`, `og:url`)
- [x] Favicon ajoute
- [x] Mobile responsive
- [x] SSL actif (HTTPS)
- [ ] Download / CTA buttons pointent vers stores reels (encore en fallback support)
- [x] Pages legales live: `/privacy`, `/terms`, `/support`
- [x] Mode clair/sombre actif

## SEO Stuff
- [x] Meta title et description definis
- [x] Robots.txt en place
- [x] Sitemap.xml en place
- [x] IndexNow key file present (`website/indexnow-key.txt`)
- [x] Script IndexNow pret (`website/indexnow-submit.sh`)
- [ ] Google Search Console connecte (manuel)
- [ ] Bing Webmaster Tools connecte (manuel)
- [ ] Sitemap soumis dans GSC/Bing (manuel)
- [ ] IndexNow ping execute en production

## Marketing Stuff
- [x] Launch post draft pret (`launch/social-media-pack.md`)
- [x] Social media assets prets (`website/assets/social/*.svg`)
- [x] Email announce template pret
- [x] Product Hunt draft pret
- [x] Plan J-1/J0/J+1 pret (`launch/day0-launch-plan.md`)
- [x] Plan communaute pret (`launch/community-outreach.md`)
- [ ] Email list notified (execution reelle)
- [ ] Friends/community ready to support (activation reelle)

## Legal Stuff
- [x] Privacy policy ecrite et liee
- [x] Terms of service ecrites et liees
- [x] Data handling documente
- [x] Data Safety / Privacy questionnaire prepare (`launch/app-privacy-questionnaire.md`)
- [x] Cookie notice present sur le site
- [ ] GDPR compliance final review (si cible UE)

## Commandes utiles
```bash
./launch/release-ready.sh scannerdocument.vercel.app "https://apps.apple.com/app/idXXXX" "https://play.google.com/store/apps/details?id=com.example.scannerdocument" GSC_TOKEN BING_TOKEN
./launch/prelaunch-audit.sh scannerdocument.vercel.app
./website/indexnow-submit.sh scannerdocument.vercel.app
```
