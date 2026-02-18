# Website Deployment Guide

Date: 2026-02-18

## Option A: Netlify (recommended)
1. Push repository to GitHub.
2. Create a new Netlify site from repo.
3. Build command: `echo 'Static site deploy'`
4. Publish directory: `website`
5. Deploy.
6. Attach custom domain.
7. SSL is auto-managed by Netlify (Let's Encrypt).

## Option B: Vercel
1. Import repository in Vercel.
2. Set project root to repository root.
3. Add rewrite or set output to static `website/` depending on project setup.
4. Deploy.
5. Attach custom domain.
6. SSL is auto-managed by Vercel.

## Post-deploy checks
Run:

```bash
./launch/prelaunch-audit.sh scannerdocument.vercel.app
```

Then:

```bash
./website/indexnow-submit.sh scannerdocument.vercel.app
```

## Manual checklist
- [ ] https://scannerdocument.vercel.app opens
- [ ] https://scannerdocument.vercel.app/privacy.html opens
- [ ] https://scannerdocument.vercel.app/support.html opens
- [ ] robots + sitemap accessible
- [ ] GSC + Bing verification completed
