# App Privacy Questionnaire (Apple + Google)

Date: 2026-02-18

## Context
This app is designed as offline-first:
- no account
- no server backend
- local processing of scanned docs
- no advertising SDK

## Apple App Store Privacy Answers (suggested)

Data collection by developer:
- Contact info: No
- Health and fitness: No
- Financial info: No
- Location: No
- Sensitive info: No
- Contacts: No
- User content: No data collected by developer servers
- Browsing history: No
- Identifiers: No tracking identifiers for ads
- Purchases: No
- Diagnostics: Only if you later enable crash analytics SDKs

Tracking:
- "Do you track users?" -> No

Data linked to user identity:
- No

Notes:
- If you add Firebase Analytics/Crashlytics later, answers must be updated.

## Google Play Data Safety (suggested)

Data collection:
- No user data collected by your backend.

Data sharing:
- No

Data processing purpose:
- Local app functionality only (on-device scan/extraction/search/export)

Security practices:
- Data is processed and stored locally on device.
- Users can delete documents inside the app.

Required declarations to review:
- Camera permission rationale: document scanning.
- File access / export rationale: local save and user-initiated share.

## Final manual checks before submit
- [ ] Verify no analytics/ads SDK added since this document.
- [ ] Verify privacy policy URL is live and HTTPS.
- [ ] Verify in-app behavior matches declared answers.
