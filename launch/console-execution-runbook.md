# Console Execution Runbook (App Store + SEO + Marketing)

Date: 2026-02-19
Domain: https://scannerdocument.vercel.app

This file is the exact manual execution sequence for remaining checklist items.

## 1) Finaliser les URLs store (bloquant CTA)
1. Recupere tes URLs definitives:
   - Apple: `https://apps.apple.com/app/idXXXXXXXXXX`
   - Play: `https://play.google.com/store/apps/details?id=com.example.scannerdocument`
2. Applique-les:
   - `./launch/configure-store-links.sh "APPLE_URL" "PLAY_URL"`
3. Regenere la fiche de soumission:
   - `./launch/build-store-submission.sh scannerdocument.vercel.app "APPLE_URL" "PLAY_URL" support@scannerdocument.vercel.app`
4. Redeploie le dossier `website/`.

## 2) Google Search Console
1. Ouvrir Search Console -> Add property -> URL prefix: `https://scannerdocument.vercel.app`
2. Methode verification: HTML tag.
3. Copier la valeur et remplacer `REPLACE_WITH_GOOGLE_TOKEN` dans `website/index.html`.
4. Redeployer.
5. Cliquer Verify.
6. Soumettre sitemap: `https://scannerdocument.vercel.app/sitemap.xml`.

## 3) Bing Webmaster Tools
1. Ouvrir Bing Webmaster -> Add site: `https://scannerdocument.vercel.app`.
2. Methode verification: Meta tag.
3. Copier la valeur et remplacer `REPLACE_WITH_BING_TOKEN` dans `website/index.html`.
4. Redeployer.
5. Cliquer Verify.
6. Soumettre sitemap: `https://scannerdocument.vercel.app/sitemap.xml`.

## 4) IndexNow
1. Verifier que cette URL est accessible:
   - `https://scannerdocument.vercel.app/indexnow-key.txt`
2. Envoyer le ping:
   - `./website/indexnow-submit.sh scannerdocument.vercel.app`

## 5) App Store Connect (Apple)
1. App Information:
   - Name, Subtitle, Category.
2. Pricing and Availability:
   - Gratis.
3. App Privacy:
   - Reponses depuis `launch/app-privacy-questionnaire.md`.
4. App Store tab:
   - Description, Keywords, Promotional Text.
   - Privacy Policy URL: `https://scannerdocument.vercel.app/privacy`
   - Support URL: `https://scannerdocument.vercel.app/support`
5. Media:
   - Screenshots selon `launch/app-store-screenshots.md`
   - App Preview (optionnel) selon `launch/app-preview-video.md`
6. Age Rating:
   - Questionnaire complet (reco: 4+).

## 6) Google Play Console
1. Main store listing:
   - App name, short description, full description.
2. Graphics:
   - Icon, screenshots, feature graphic.
3. App content:
   - Data safety (voir `launch/app-privacy-questionnaire.md`)
   - Ads: No
   - Target audience + content rating.
4. Contact details:
   - Website: `https://scannerdocument.vercel.app`
   - Email: `support@scannerdocument.vercel.app`
   - Privacy policy: `https://scannerdocument.vercel.app/privacy`

## 7) Marketing execution (Day 0)
1. Publier post launch (base dans `launch/social-media-pack.md`).
2. Envoyer email liste.
3. Activer support amis/communaute (`launch/community-outreach.md`).
4. Repondre aux retours sous 24h.

## 8) Verification finale
1. `./launch/prelaunch-audit.sh scannerdocument.vercel.app`
2. Verifier:
   - aucun placeholder restant,
   - pages legales en 200,
   - CTA store ouvrent les bons liens.
