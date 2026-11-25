# Premium, OCR, and Optional Cloud Architecture

**Status:** Architecture decision record for Milestone 8. This document defines safe integration boundaries; it does not claim that billing, OCR, ads, or cloud APIs are already implemented.

## 1. Product constraints

- PDF scanning, import, local editing, merge/split, compression, annotation, preview, and export remain usable without an account or internet connection.
- A premium entitlement must never lock, hide, or delete documents already stored on the device.
- Cloud backup and cloud OCR are opt-in network features. They are not prerequisites for local workflows.
- Never grant paid access solely because a client-side boolean, preference, or locally edited database row says that the user is premium.
- No billing keys, service-account credentials, signing keys, or provider secrets belong in the Flutter repository.

## 2. Premium purchase and entitlement verification

### Recommended Android purchase path

Use Google Play Billing through Flutter's `in_app_purchase` integration when the app's Play Console product catalog is ready. Support subscription products and, if the product strategy requires it, a non-consumable lifetime product. Product identifiers, prices, subscription periods, and trial policy must be created in Play Console rather than invented in source code.

### Trust boundary

1. Flutter requests available products and launches the Google Play purchase flow.
2. Flutter receives the purchase result and sends the purchase token, product identifier, and app package identifier to the backend over TLS.
3. The Node.js backend verifies the purchase with the Google Play Developer API and checks package/product identity, purchase state, acknowledgement state, expiry, and revocation.
4. The backend stores the verified entitlement against the account and returns a short-lived, server-signed entitlement document.
5. Flutter verifies the signature and expiry before enabling premium-only UI. The backend remains authoritative for renewal, cancellation, refund, and revocation.
6. The backend acknowledges/consumes purchases as required by the verified Play purchase state and API flow. Retries must be idempotent.

Do not ship a client-only "Restore premium" toggle. Restore purchases means querying Play purchases and re-verifying them with the backend.

### Offline behavior

- Cache the last server-verified entitlement document in app-private storage.
- Give that cached document a bounded offline validity window (recommended maximum: 72 hours after last verification); after expiry, premium-only online services require reconnection and revalidation.
- Previously downloaded files and all free/offline tools remain available regardless of entitlement refresh state.
- Do not use offline grace to authorize new cloud OCR jobs or cloud backup operations.

### Feature policy

| Feature | Proposed access |
|---|---|
| Local scanning, import, preview, rotate/crop, merge/split, basic compression, local annotation, share/export | Free |
| Batch processing | Premium candidate; current implementation remains available until purchase catalog and gating are approved |
| Advanced compression profiles | Premium |
| Premium templates | Premium |
| Remove ads | Premium entitlement suppresses ads; ads are not integrated yet |
| OCR credits | Credit balance verified and consumed by backend; provider cost is never trusted to the client |
| Cloud backup | Premium/account feature; user-triggered and encrypted |

The current batch compressor is implemented and device-tested. Do not silently start blocking it behind an entitlement before product IDs, purchase verification, restore behavior, and support policy are ready.

## 3. OCR provider decision

**Provider is intentionally not selected yet.** The required document languages have not been specified, and language support is a first-order requirement for OCR quality.

Evaluate candidates against:
- Required languages and mixed-language documents, including Urdu/Arabic if required.
- On-device/offline availability versus cloud-only processing.
- Printed text accuracy, tables, multi-column layouts, handwriting, and low-quality scans.
- Android binary size, memory, latency, and minimum API requirements.
- License and commercial redistribution terms.
- Privacy, data retention, regional processing, and deletion guarantees.
- Per-page cost, free quota, and credit accounting if cloud OCR is selected.

Preferred order:
1. Prefer on-device OCR for languages supported at acceptable quality, so private documents can stay on the device.
2. Use an opt-in cloud OCR adapter only for unsupported languages or higher-accuracy processing when the user explicitly requests it.
3. Never upload a document silently. Show what will be sent, why, and the provider/data-retention implications.

OCR result model should preserve page number, text blocks, bounding boxes normalized to page coordinates, confidence where available, language, and engine/version metadata. Keep original PDF and OCR text as separate artifacts.

## 4. Optional Node.js API boundary

No backend is required for the current offline app. If account/cloud functionality is approved, the Node.js reference project can host versioned REST endpoints.

Proposed contract (not implemented):

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/v1/billing/google-play/verify` | Verify a purchase token and return server-signed entitlement |
| GET | `/v1/entitlements` | Read the authenticated account's current entitlement |
| POST | `/v1/ocr/jobs` | Submit an explicitly requested OCR job and debit/reserve credits idempotently |
| GET | `/v1/ocr/jobs/:jobId` | Read OCR job status/result |
| GET | `/v1/ocr/credits` | Read available OCR credits and transaction history |
| POST | `/v1/backups` | Create an encrypted backup upload session |
| GET | `/v1/backups` | List the account's backup snapshots |
| GET | `/v1/backups/:backupId` | Obtain a short-lived download URL/stream |
| DELETE | `/v1/backups/:backupId` | Delete a backup and schedule storage cleanup |

### Backend requirements

- Authenticate every account-scoped request; authorize ownership for every backup/job identifier.
- Verify Google Play purchases server-side; validate RTDN notifications and periodically reconcile subscription state.
- Make purchase verification, OCR credit reservations, and backup creation idempotent.
- Store OCR credit ledger entries as append-only transactions; never trust a client-supplied balance.
- Use short-lived signed upload/download URLs, strict size/type limits, malware/content validation where appropriate, and rate limits.
- Encrypt backup objects at rest and in transit. Define key ownership, retention, deletion, and recovery before launch.
- Keep document bytes out of logs. Redact purchase tokens and personal data.
- Document privacy policy, consent, retention, account deletion, backup deletion, and failure recovery before enabling cloud features.

## 5. Release gates before implementation

The following product decisions are required before enabling paid/network features:
- Play Console product catalog and subscription/lifetime pricing.
- Whether accounts are required for premium, and the account identity provider.
- OCR language list and whether Urdu/Arabic handwriting is in scope.
- OCR provider and processing region, if cloud OCR is needed.
- Cloud storage provider, encryption/key-management ownership, retention, and backup quota.
- Ads provider and consent requirements, if ads are introduced.

Until those decisions are approved, keep all cloud and billing adapters disabled and retain the offline-first free experience.
