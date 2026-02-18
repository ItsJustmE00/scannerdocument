# SEO Setup Guide (Google + Bing + IndexNow)

Date: 2026-02-18

## 1) Avant tout
- Remplacer `https://your-domain.com` dans tous les fichiers `website/`.
- Option rapide: `./launch/configure-domain.sh your-domain.com <google_token> <bing_token>`
- Option tout-en-un: `./launch/release-ready.sh <domain> <apple_url> <play_url> <google_token> <bing_token>`
- Deployer le dossier `website/` sur ton hebergeur (Netlify, Vercel, Cloudflare Pages, etc.).
- Verifier que le site est servi en HTTPS.

## 2) Google Search Console
1. Ajouter la propriete domaine ou URL-prefix.
2. Verifier avec la meta tag ou DNS TXT.
3. Soumettre: `https://your-domain.com/sitemap.xml`.
4. Verifier l'indexation de `/`, `/privacy.html`, `/terms.html`, `/support.html`.

## 3) Bing Webmaster Tools
1. Ajouter le site.
2. Verifier via XML file, meta tag ou DNS.
3. Soumettre le sitemap.

## 4) IndexNow
Le fichier de cle est deja cree: `website/indexnow-key.txt`.
Script pret: `website/indexnow-submit.sh`.

Apres deploiement, tester:
- `https://your-domain.com/indexnow-key.txt`

Puis pinger IndexNow:

```bash
curl "https://api.indexnow.org/indexnow?url=https://your-domain.com/&key=8d44f8e8f0a94f8da2f8181e63811235"
```

Pour soumettre plusieurs URLs:

```bash
curl -X POST "https://api.indexnow.org/indexnow" \
  -H "Content-Type: application/json" \
  -d '{
    "host": "your-domain.com",
    "key": "8d44f8e8f0a94f8da2f8181e63811235",
    "keyLocation": "https://your-domain.com/indexnow-key.txt",
    "urlList": [
      "https://your-domain.com/",
      "https://your-domain.com/privacy.html",
      "https://your-domain.com/terms.html",
      "https://your-domain.com/support.html"
    ]
  }'
```

## 5) Checklist finale SEO
- Title + description: OK
- Open Graph: OK
- robots.txt: OK
- sitemap.xml: OK
- verification tokens: a remplir
- soumission GSC/Bing: manuelle
- audit local/live: `./launch/prelaunch-audit.sh [domain]`
