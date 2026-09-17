# Mantirigam Mobile App Integration Contract

**Single source of truth** for the Flutter `mantirigam` application integrating with this Admin + Backend API.

This document describes **only what is implemented** in the current codebase. Anything not implemented is marked `NOT IMPLEMENTED` or `RESERVED / FUTURE`.

Do not invent endpoints, fields, or Flutter package choices beyond what this contract states.

---

## 1. Scope and authority

| Concern | Authority |
| ------- | --------- |
| Authentication identity | Backend (verified Google ID token → user access JWT) |
| Entitlement / library access | Backend |
| Payment success | Backend (signature + gateway verification) |
| Book / chapter content exposure | Backend access checks |
| Branding, guest flags, app update | Backend `GET /app-config` |
| Admin cookies / admin JWTs | **Not** mobile auth — never use from Flutter |

The mobile app must treat the backend as authoritative for ownership, purchase, and content access.

---

## 2. Environment / base URL

### API prefix

All product APIs are under:

```text
/api/v1
```

### Development

From repository examples (`backend/.env.example`, `README.md`):

```text
http://localhost:5050/api/v1
```

Notes:

- Application code defaults `PORT` to `5000` when unset.
- Local `.env.example` uses `5050` because macOS AirPlay often occupies `5000`.
- Frontend admin uses `NEXT_PUBLIC_API_BASE_URL` (example value may point at a Render host). That value is for the **admin web app**, not a Flutter hard requirement.

### Production

```text
Production API URL: CONFIGURE FROM DEPLOYMENT ENVIRONMENT
```

No production mobile base URL is committed as a Flutter constant. Deployed docs/examples may show placeholders such as `https://your-api.onrender.com/api/v1`. Flutter must configure the base URL via **flavor / environment configuration** (e.g. `--dart-define`, flavor env files), not by hardcoding a production host in source unless your release process injects it.

### Flutter configuration guidance

```text
API_BASE_URL = <scheme>://<host>[:port]/api/v1
```

All paths in this document are relative to that base (or absolute from host root as `/api/v1/...`).

---

## 3. Common API contract

### Success envelope

```json
{
  "success": true,
  "data": {}
}
```

### Error envelope

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message"
  }
}
```

### Paginated success

Used when the controller calls `sendPaginated`:

```json
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Pagination rules (implemented)

| Parameter | Default | Maximum | Notes |
| --------- | ------- | ------- | ----- |
| `page` | `1` | — | Query string; invalid values fall back to default |
| `limit` | `20` | `50` | Values above 50 are capped at 50 |

Confirmed paginated **mobile** endpoints:

- `GET /api/v1/books`
- `GET /api/v1/library`

`GET /api/v1/announcements` returns a **non-paginated** array in `data` (max 10 items).

---

## 4. Authorization boundary

### Mobile authentication

Use the **Mantirigam user access token** returned by Google login:

```http
Authorization: Bearer <accessToken>
```

### Do not use from Flutter

- Admin session cookies
- Admin login / refresh / me / logout endpoints
- Admin JWTs
- Arbitrary client-supplied `userId` as identity (backend derives user from the verified Bearer token)
- Razorpay secret key, webhook secret, JWT signing secret, Google client secret, Mongo credentials

Optional Bearer auth is used only where implemented (chapter content). Catalogue and book details are public without a token.

---

## 5. Authentication — Google login

### Endpoint

```http
POST /api/v1/auth/google
```

**Auth:** none (public)  
**Rate limit:** 10 requests / 15 minutes per IP (`RATE_LIMITED` / HTTP 429)

### Request body

Only `idToken` is allowed. Extra identity fields are rejected.

```json
{
  "idToken": "<Google ID token from Google Sign-In>"
}
```

### Backend behavior (implemented)

1. Verifies the Google ID token server-side (audience = configured `GOOGLE_CLIENT_ID`).
2. Requires issuer `https://accounts.google.com` or `accounts.google.com`.
3. Requires `email_verified === true`.
4. Normalizes email: trim + lowercase.
5. Canonical identity is Google `sub` (`googleSubjectId`).
6. Existing user by `googleSubjectId`: updates name/picture/lastLogin if needed; issues access token.
7. New user: creates `ACTIVE` user with Google subject, email, name, optional profile image.
8. Email already exists with a **different** Google subject → `GOOGLE_ACCOUNT_CONFLICT` (409).
9. User status not `ACTIVE` → `USER_INACTIVE` (403).
10. The Google ID token is **not** stored, **not** logged as a secret payload, and **not** returned to the client.

### Success response (HTTP 200)

```json
{
  "success": true,
  "data": {
    "accessToken": "<JWT>",
    "user": {
      "id": "<mongoObjectId>",
      "name": "Reader Name",
      "email": "user@example.com",
      "profileImageUrl": "https://..." 
    }
  }
}
```

`profileImageUrl` may be `null`.

### Error codes (Google auth)

| Code | HTTP | Meaning |
| ---- | ---- | ------- |
| `VALIDATION_ERROR` | 400 | Body not an object, or forbidden extra fields |
| `GOOGLE_TOKEN_INVALID` | 401 | Missing/invalid token, bad issuer, verify failure |
| `GOOGLE_EMAIL_NOT_VERIFIED` | 401 | Email not verified by Google |
| `USER_INACTIVE` | 403 | User exists but is inactive |
| `GOOGLE_ACCOUNT_CONFLICT` | 409 | Email linked to another Google identity |
| `GOOGLE_AUTH_FAILED` | 500 | Misconfiguration / unexpected failure |
| `RATE_LIMITED` | 429 | Too many attempts |

---

## 6. Application session (mobile user)

### Access token

- Issued by `POST /auth/google` as `data.accessToken`.
- Type claim: `user_access`.
- Issuer: `mantirigam-admin-api`.
- Audience: `mantirigam-user`.
- Expiry: configured by backend env `JWT_ACCESS_EXPIRES_IN` (example default `15m`). Flutter must not assume a fixed duration beyond treating expiry as possible.

### Authorization header

```http
Authorization: Bearer <accessToken>
```

### Token storage (Flutter expectations)

Store the access token in **platform-secure storage** (Keychain / EncryptedSharedPreferences or equivalent). Do not store admin cookies. Do not embed signing secrets.

### Refresh

```text
POST /api/v1/auth/refresh
```

**NOT IMPLEMENTED** for Mantirigam mobile users.

Admin-only refresh exists at `POST /api/v1/auth/admin/refresh` — **DO NOT CALL FROM FLUTTER**.

### Logout

```text
POST /api/v1/auth/logout
```

**NOT IMPLEMENTED** for Mantirigam mobile users.

Admin logout exists at `POST /api/v1/auth/admin/logout` — **DO NOT CALL FROM FLUTTER**.

### When access token expires

Protected mobile endpoints return:

- `TOKEN_EXPIRED` (401) when the JWT is expired, or
- `TOKEN_INVALID` (401) when the JWT is otherwise invalid, or
- `UNAUTHENTICATED` (401) when the Bearer header is missing / user inactive / not found

**Mobile handling:** clear local session and require Google Sign-In again. There is no mobile refresh endpoint in this API.

### Dedicated `/me` endpoint

```text
GET /api/v1/me
```

**NOT IMPLEMENTED.**

Public user fields available to the app today:

- From Google login response: `id`, `name`, `email`, `profileImageUrl`
- From library / payments as described below (book ownership data, not a profile resource)

---

## 7. Book catalogue

### List books

```http
GET /api/v1/books
```

**Auth:** none

#### Query parameters

| Name | Values | Behavior |
| ---- | ------ | -------- |
| `page` | positive int | Pagination (default 1) |
| `limit` | positive int | Pagination (default 20, max 50) |
| `language` | `ta` \| `en` \| `hi` | Filter |
| `accessType` | `FREE` \| `PAID` | Filter |
| `search` | string | Case-insensitive match on `title` or `author` |

`status` query is **ignored** on the public list (public filter always forces `PUBLISHED`).

#### Sorting

`publishedAt` descending, then `_id` descending.

#### Visibility

Only books with `status: "PUBLISHED"` are returned.

| Status | Visible on mobile catalogue? |
| ------ | ---------------------------- |
| `DRAFT` | No |
| `PUBLISHED` | Yes |
| `UNPUBLISHED` | No |
| `ARCHIVED` | No |

#### Response (HTTP 200)

```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "title": "...",
      "description": "...",
      "author": "...",
      "language": "ta",
      "coverImage": "https://host/api/v1/media/covers/...",
      "accessType": "FREE",
      "price": 0,
      "currency": "INR",
      "previewEnabled": false,
      "previewConfig": {
        "type": "NONE"
      },
      "status": "PUBLISHED",
      "publishedAt": "2026-01-01T00:00:00.000Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 1,
    "totalPages": 1
  }
}
```

Notes:

- `coverImage` is omitted from the object when unset (list/detail serializer); library responses use `null` when missing.
- `price` is an **integer minor unit** (paise for INR). Example: ₹299.00 → `29900`.
- `previewEnabled` / `previewConfig` may be present on public books, but **paid preview reading is not implemented** (see Guest Access).

### Book details

```http
GET /api/v1/books/:id
```

**Auth:** none  
**Not found:** `BOOK_NOT_FOUND` (404) for invalid id or non-`PUBLISHED` book.

Same public book shape as list items (single object in `data`).

### Internal vs public fields

**Public mobile fields:** as in `toPublicBook` above.

**Not exposed on public book APIs:** Mongo `_id` object form, `createdAt` / `updatedAt` (admin detail only), admin audit metadata, unpublished/draft/archived books.

---

## 8. Chapters

### List chapters (metadata only)

```http
GET /api/v1/books/:bookId/chapters
```

**Auth:** none  
**Book must be `PUBLISHED`.**

Returns only chapters with `status: "PUBLISHED"`, sorted by `chapterNumber` ascending, then `_id`.

**Does not include `content`.**

```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "bookId": "...",
      "chapterNumber": 1,
      "title": "Chapter 1",
      "contentFormat": "RICH_TEXT",
      "status": "PUBLISHED"
    }
  ]
}
```

Draft / unpublished / archived chapters are not listed.

### Chapter content (reader)

```http
GET /api/v1/books/:bookId/chapters/:chapterId
```

**Auth:** optional Bearer (`optionalAuthenticateUser`)

If a Bearer token is sent, it must be valid; invalid tokens still fail with 401.

#### Access rules (implemented)

1. Book must be `PUBLISHED`; chapter must be `PUBLISHED` and belong to that book.
2. **`accessType === "PAID"`:** requires an **ACTIVE** entitlement for `(userId, bookId)`. Otherwise `PURCHASE_REQUIRED` (403). Guest cannot read paid chapters.
3. **`accessType === "FREE"`:**
   - If `ALLOW_GUEST_FREE_BOOK_READING` is `true` → guests may read without a token.
   - If guest free reading is `false` and no authenticated user → `AUTHENTICATION_REQUIRED` (401).
4. Book `accessType` alone is **not** sufficient for paid content; entitlement is required.
5. Full paid chapter `content` is only returned after entitlement check succeeds.

#### Paid preview

```text
Paid preview is RESERVED / NOT IMPLEMENTED in the current mobile API.
```

`ALLOW_PAID_BOOK_PREVIEW` is forced to `false` in public app-config. Preview fields on books do not unlock unpaid chapter content.

#### Success body

Chapter summary fields plus:

```json
{
  "success": true,
  "data": {
    "id": "...",
    "bookId": "...",
    "chapterNumber": 1,
    "title": "Chapter 1",
    "contentFormat": "RICH_TEXT",
    "status": "PUBLISHED",
    "content": {
      "version": 1,
      "blocks": []
    }
  }
}
```

---

## 9. Rich Text Reader Contract (frozen V1)

Canonical storage is **JSON**, not HTML and not Markdown.

```json
{
  "version": 1,
  "blocks": [
    {
      "id": "blk_...",
      "type": "paragraph",
      "text": "Hello world",
      "marks": [
        { "start": 0, "end": 5, "type": "bold" }
      ]
    }
  ]
}
```

### Supported block types

| `type` | Required fields |
| ------ | --------------- |
| `paragraph` | `id`, `text`, optional `marks` |
| `heading` | `id`, `level` (1\|2\|3), `text`, optional `marks` |
| `bullet_list` | `id`, `items: [{ "text": "..." }]` |
| `ordered_list` | `id`, `items: [{ "text": "..." }]` |
| `quote` | `id`, `text`, optional `marks` |

### Inline marks

Types: `bold`, `italic`

```json
{
  "start": 8,
  "end": 13,
  "type": "bold"
}
```

Offsets are character indices into that block’s `text` (`start` inclusive, `end` exclusive in typical rendering; validate against backend storage invariants).

### Block IDs

- Stable string ids (generated as `blk_` + random base64url).
- **MUST NOT** treat `id` as an array index.
- Bookmarks (when implemented client-side against this contract) must reference `blockId`.

### Flutter rendering

Render the JSON document to native widgets / a custom painter. No specific Flutter package is mandated by the backend. Do not download or render source PDF/DOCX for reading.

---

## 10. Guest access

Global settings keys (admin-managed via app settings / app-config):

| Key | Effect |
| --- | ------ |
| `ALLOW_GUEST_FREE_BOOK_READING` | When `true`, unauthenticated users may load **FREE** published chapter content. Default when unset: **false**. |
| `ALLOW_PAID_BOOK_PREVIEW` | Always treated as **false** / not implemented for reading. |

Exposed to mobile on `GET /app-config` as:

```json
"guestAccess": {
  "allowGuestFreeBookReading": false,
  "allowPaidBookPreview": false
}
```

### How this affects mobile UX

| Action | Guest | Authenticated |
| ------ | ----- | ------------- |
| Browse catalogue / book details | Yes | Yes |
| List chapter titles | Yes | Yes |
| Read FREE chapter content | Only if `allowGuestFreeBookReading` | Yes |
| Read PAID chapter content | Never (needs ACTIVE entitlement) | Only with ACTIVE entitlement |
| Create payment / library | No | Yes |

Flutter must **not** hardcode guest rules; consume `guestAccess` from app-config and respect chapter API errors.

---

## 11. App config

```http
GET /api/v1/app-config
```

**Auth:** none  
**Cache-Control:** `public, max-age=60`

### Public response shape (mobile-safe)

```json
{
  "success": true,
  "data": {
    "version": 0,
    "branding": {
      "appName": "Mantirigam",
      "tagline": "",
      "logoUrl": null,
      "primaryColor": "#6B21A8",
      "secondaryColor": "#F5F0E8",
      "buttonColor": "#6B21A8"
    },
    "home": {
      "showHero": true,
      "heroTitle": "",
      "heroSubtitle": "",
      "heroImageUrl": null,
      "showFeaturedBooks": true,
      "featuredBooks": [{ "id": "...", "title": "..." }],
      "showContinueReading": true,
      "showCategories": true,
      "showLatestBooks": true
    },
    "catalogue": {
      "showLanguageFilter": true,
      "showFreeBooks": true,
      "showPaidBooks": true,
      "defaultLanguage": "all"
    },
    "guestAccess": {
      "allowGuestFreeBookReading": false,
      "allowPaidBookPreview": false
    },
    "features": {
      "bookmarksEnabled": true,
      "readingProgressEnabled": true,
      "continueReadingEnabled": true,
      "announcementsEnabled": true,
      "featuredBooksEnabled": true
    },
    "appUpdate": {
      "android": {
        "latestVersion": null,
        "minimumVersion": null,
        "storeUrl": null
      },
      "ios": {
        "latestVersion": null,
        "minimumVersion": null,
        "storeUrl": null
      },
      "forceUpdateEnabled": false,
      "updateMessage": ""
    }
  }
}
```

### Field classification

| Area | Mobile-safe | Notes |
| ---- | ----------- | ----- |
| `version`, branding, home (public), catalogue, guestAccess, features, appUpdate | Yes | Dynamic from admin |
| Admin `featuredBookIds` raw list / admin featured status fields | Admin-only | Public only gets published `{ id, title }` |
| `guestAccess.paidPreviewAvailable` | Admin-shaped only | Public payload forces `allowPaidBookPreview: false` |
| Feature flags for bookmarks / progress | Returned | **Server routes for progress/bookmarks are NOT IMPLEMENTED** — treat flags as reserved UX until APIs exist |

Flutter should drive branding, catalogue toggles, featured books, guest access, and update prompts from this payload.

---

## 12. Announcements

```http
GET /api/v1/announcements
```

**Auth:** none  
**Cache-Control:** `public, max-age=60`

### Behavior

- If `features.announcementsEnabled === false` → `data: []`.
- Otherwise returns up to **10** announcements with `status: "PUBLISHED"`.
- Sort: `displayOrder` ASC, `createdAt` DESC, `_id` DESC.

### Public fields

```json
{
  "success": true,
  "data": [
    {
      "id": "...",
      "title": "...",
      "message": "...",
      "imageUrl": null,
      "actionLabel": "",
      "actionUrl": null,
      "displayOrder": 1,
      "publishedAt": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

Admin-only fields (status workflow, archive, etc.) are not returned.

---

## 13. App update contract

From `app-config.appUpdate`:

```text
appUpdate.android.latestVersion
appUpdate.android.minimumVersion
appUpdate.android.storeUrl

appUpdate.ios.latestVersion
appUpdate.ios.minimumVersion
appUpdate.ios.storeUrl

appUpdate.forceUpdateEnabled
appUpdate.updateMessage
```

### Version format

Semantic-style strings validated admin-side as `1.2.3` (`isAppVersion`). Null means unset.

### Client interpretation (Flutter responsibility)

The **backend does not block old API clients** by version. Flutter should:

1. Compare local app version to platform `minimumVersion` / `latestVersion`.
2. If below `minimumVersion` and versions are set → treat as **required update** (especially when `forceUpdateEnabled` is true; still show `updateMessage` / store URL).
3. If below `latestVersion` but at/above minimum → **optional update**.
4. Open platform `storeUrl` (HTTPS when configured for updates).

---

## 14. Payment flow (Razorpay)

### Mobile sequence

```text
Authenticated User
      ↓
Select PAID Book
      ↓
POST /payments/create-order { bookId }
      ↓
Receive orderId, amount (paise), currency, keyId
      ↓
Open Razorpay Checkout (keyId + orderId + amount)
      ↓
Razorpay Payment
      ↓
POST /payments/verify { razorpayOrderId, razorpayPaymentId, razorpaySignature }
      ↓
Backend verifies signature + ownership + amount + currency + captured status
      ↓
Purchase SUCCESS + LIFETIME entitlement ACTIVE
      ↓
GET /library / chapter content unlocks
```

Flutter must **not** grant access from client-side Razorpay success alone. Backend verification (or webhook fulfillment) is authoritative. Prefer calling verify, then confirm with status/library.

### Create order

```http
POST /api/v1/payments/create-order
Authorization: Bearer <accessToken>
```

Request — **only** `bookId` allowed:

```json
{
  "bookId": "<24-hex ObjectId>"
}
```

Success **HTTP 201**:

```json
{
  "success": true,
  "data": {
    "orderId": "order_...",
    "amount": 29900,
    "currency": "INR",
    "keyId": "<RAZORPAY_KEY_ID>"
  }
}
```

`amount` is minor units (paise). `keyId` is the **public** Razorpay key id only.

Idempotency: pending purchase for same user+book returns the existing order payload.

### Verify payment

```http
POST /api/v1/payments/verify
Authorization: Bearer <accessToken>
```

```json
{
  "razorpayOrderId": "order_...",
  "razorpayPaymentId": "pay_...",
  "razorpaySignature": "..."
}
```

Success **HTTP 200** (`PaymentStatusResult`):

```json
{
  "success": true,
  "data": {
    "orderId": "order_...",
    "status": "CAPTURED",
    "purchaseStatus": "SUCCESS",
    "entitled": true
  }
}
```

Payment `status` values in the system include: `CREATED`, `AUTHORIZED`, `CAPTURED`, `FAILED`, `REFUNDED`.

### Payment status (retry)

```http
GET /api/v1/payments/:orderId/status
Authorization: Bearer <accessToken>
```

Same `PaymentStatusResult` shape. Ownership enforced (`PAYMENT_OWNERSHIP_MISMATCH` if another user’s order).

Use when verify is interrupted; webhook may also fulfill asynchronously.

### Webhook

```http
POST /api/v1/payments/webhook
```

**DO NOT CALL FROM FLUTTER.** Razorpay → backend only. Requires valid webhook signature. Returns `{ "received": true }` on success.

---

## 15. Library / entitlement

```http
GET /api/v1/library
Authorization: Bearer <accessToken>
```

Query: `page`, `limit` (same pagination rules).

Returns **ACTIVE** entitlements for the authenticated user (newest `grantedAt` first), joined to book metadata:

```json
{
  "success": true,
  "data": [
    {
      "bookId": "...",
      "title": "...",
      "language": "ta",
      "coverImage": null,
      "accessType": "PAID",
      "entitlementType": "LIFETIME",
      "grantedAt": "2026-01-01T00:00:00.000Z"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 1, "totalPages": 1 }
}
```

### Semantics

```text
Client Razorpay success
≠
Entitlement

Backend verification / webhook
→ Purchase SUCCESS
→ Entitlement LIFETIME ACTIVE
→ Library row + paid chapter access
```

- Duplicate purchase while already entitled → `BOOK_ALREADY_OWNED` (409).
- Revoked entitlements do **not** appear in library and do not unlock chapters.
- FREE books are readable per guest/auth rules; they are not required to appear in library via purchase.

---

## 16. Reading progress

```text
GET /api/v1/progress
POST /api/v1/progress
PATCH /api/v1/progress/:chapterId
```

**NOT IMPLEMENTED** (no public routes).

A Mongo model exists (`reading_progress` with `userId`, `bookId`, `chapterId`, `progress` in `[0, 1]`, `lastReadAt`) but there is **no mobile HTTP API**.

`features.readingProgressEnabled` / `showContinueReading` may be true in app-config — treat sync APIs as **RESERVED / FUTURE**.

---

## 17. Bookmarks

```text
GET /api/v1/bookmarks
POST /api/v1/bookmarks
DELETE /api/v1/bookmarks/:id
```

**NOT IMPLEMENTED** (no public routes).

Model + frozen V1 position contract exist in code for future use:

```json
{
  "blockId": "blk_...",
  "startOffset": 10,
  "endOffset": 28
}
```

Rules encoded in `assertBookmarkPosition`:

- Non-empty `blockId`
- Integer offsets ≥ 0
- `startOffset < endOffset`
- Single-block selection only (V1)
- Optional `note` field on model (max 2000) — **no API yet**

Do not call bookmark endpoints until they are implemented.

---

## 18. Cover / image handling

### Cover images served by API

```http
GET /api/v1/media/covers/:id
```

**Auth:** none  
Returns raw image bytes with `Content-Type` and `Cache-Control: public, max-age=86400`.

Cover **upload** is admin-only: `POST /api/v1/admin/covers` — **DO NOT CALL FROM FLUTTER**.

### How mobile receives URLs

- Book `coverImage` is typically an absolute HTTPS (or local HTTP) URL to `/api/v1/media/covers/:id`.
- Announcement `imageUrl` and branding `logoUrl` / `heroImageUrl` are URL strings when set (admin-configured). Flutter loads them over HTTPS in production.

No mobile upload endpoints.

---

## 19. Mobile security requirements

### Transport and secrets

- Use HTTPS in production.
- Send Bearer user access token only on authenticated calls.
- Store tokens in secure storage.
- Never ship: JWT signing secret, admin credentials, Razorpay **secret** key, webhook secret, Google client **secret**, Mongo URI, or other backend secrets.
- Razorpay Checkout may use the **public** `keyId` returned by create-order.

### Trust boundaries

- Do not trust client-side payment success for unlock.
- Do not invent client-side entitlement authority.
- Do not send admin cookies or admin JWTs.
- Do not pass arbitrary `userId` for identity.
- No direct MongoDB or storage-bucket access from the app.

### Content policy

- Online reader only (see Offline Policy).
- No PDF/DOCX rendering of catalogue books in the mobile reader.
- No persistent downloadable full-book content store.

### Device UI hardening (client-side; not guaranteed by backend)

- Android: consider `FLAG_SECURE` for reader screens.
- iOS: follow platform guidance for screen capture / overlay where applicable.
- These harden the UI; they do **not** prevent another physical camera.

---

## 20. Offline policy

```text
ONLINE ONLY
```

Implemented product stance for mobile:

- No offline book reading product mode
- No book / PDF / DOCX download for offline reading
- No offline entitlement authority
- No persistent full-book local cache of chapter JSON

Temporary HTTP image/cache for covers/config (respecting Cache-Control) is distinct from offline content storage and must not become a full offline library.

---

## 21. Error catalogue (mobile-relevant)

### Authentication

| Code | HTTP | Meaning | Mobile guidance |
| ---- | ---- | ------- | --------------- |
| `UNAUTHENTICATED` | 401 | Missing/invalid session or inactive user | Re-login |
| `TOKEN_EXPIRED` | 401 | Access JWT expired | Re-login (no mobile refresh) |
| `TOKEN_INVALID` | 401 | Bad JWT | Re-login |
| `AUTHENTICATION_REQUIRED` | 401 | Free chapter needs login when guests disallowed | Prompt Google Sign-In |
| `GOOGLE_TOKEN_INVALID` | 401 | Google token rejected | Retry Google Sign-In |
| `GOOGLE_EMAIL_NOT_VERIFIED` | 401 | Unverified Google email | Show error |
| `USER_INACTIVE` | 403 | Account inactive | Block app use |
| `GOOGLE_ACCOUNT_CONFLICT` | 409 | Email conflict | Support / alternate account |
| `GOOGLE_AUTH_FAILED` | 500 | Server/config failure | Retry later |
| `RATE_LIMITED` | 429 | Auth rate limited | Back off |

### Authorization / access

| Code | HTTP | Meaning | Mobile guidance |
| ---- | ---- | ------- | --------------- |
| `PURCHASE_REQUIRED` | 403 | Paid chapter without entitlement | Show purchase flow |
| `PAYMENT_OWNERSHIP_MISMATCH` | 403 | Order belongs to another user | Do not retry as success |

### Books / chapters

| Code | HTTP | Meaning | Mobile guidance |
| ---- | ---- | ------- | --------------- |
| `BOOK_NOT_FOUND` | 404 | Missing / not published | Show unavailable |
| `CHAPTER_NOT_FOUND` | 404 | Missing / not published | Show unavailable |
| `BOOK_NOT_PURCHASABLE` | 409 | Not published paid book | Disable buy |
| `BOOK_ALREADY_OWNED` | 409 | Already entitled | Refresh library / open book |

### Payment

| Code | HTTP | Meaning | Mobile guidance |
| ---- | ---- | ------- | --------------- |
| `VALIDATION_ERROR` | 400 | Bad body / forbidden fields | Fix client payload |
| `INVALID_PAYMENT_SIGNATURE` | 400 | Signature mismatch | Do not unlock; retry carefully |
| `PAYMENT_AMOUNT_MISMATCH` | 400 | Amount mismatch | Contact support / retry status |
| `PAYMENT_CURRENCY_MISMATCH` | 400 | Currency mismatch | Same |
| `PAYMENT_VERIFICATION_FAILED` | 400/500 | Gateway/config/verify failure | Retry status; show error |
| `PAYMENT_NOT_FOUND` | 404 | Unknown order | Restart purchase |
| `PAYMENT_NOT_CAPTURED` | 409 | Not captured yet | Poll status / wait for webhook |
| `INVALID_WEBHOOK_SIGNATURE` | 400 | Webhook only | N/A to Flutter |

### Covers (public get)

| Code | HTTP | Meaning | Mobile guidance |
| ---- | ---- | ------- | --------------- |
| `COVER_NOT_FOUND` | 404 | Missing cover bytes | Placeholder image |

### Validation / protocol

| Code | HTTP | Meaning | Mobile guidance |
| ---- | ---- | ------- | --------------- |
| `INVALID_JSON` | 400 | Malformed JSON body | Fix client |
| `NOT_FOUND` | 404 | Unknown route | Wrong path/version |
| `INTERNAL_ERROR` | 500 | Unexpected | Retry / error UI |

Admin-only error codes (imports, admin app-config conflicts, etc.) are omitted from the mobile catalogue intentionally.

---

## 22. HTTP status behavior (observed)

| Status | Used for |
| ------ | -------- |
| 200 | Typical success |
| 201 | Create order (and some admin creates) |
| 400 | Validation, bad signatures, invalid JSON |
| 401 | Auth required / invalid / expired tokens |
| 403 | Inactive user, purchase required, ownership mismatch |
| 404 | Missing resources / routes |
| 409 | Business conflicts (owned, not purchasable, not captured) |
| 413 | Upload too large (admin covers/imports; not mobile flows) |
| 422 | Some admin publish/validation paths |
| 429 | Google / admin login rate limits |
| 500 | Internal / misconfiguration |
| 501 | Legacy authorize stub — not a mobile path |

Flutter guidance:

- **401** → clear session, Google Sign-In again (no mobile refresh).
- **403** → access / entitlement / inactive messaging.
- **404** → resource unavailable UI.
- **409** → business conflict UI (already owned, payment pending capture).
- **422** → uncommon on mobile paths; treat as validation failure if seen.
- **429** → exponential backoff.
- **5xx** → retry with backoff + error UI.

---

## 23. Cache behavior

| Endpoint | Cache-Control |
| -------- | ------------- |
| `GET /app-config` | `public, max-age=60` |
| `GET /announcements` | `public, max-age=60` |
| `GET /media/covers/:id` | `public, max-age=86400` |

Recommended Flutter behavior:

- Fetch app-config (and announcements) on cold start.
- Refresh on resume if stale (>60s) or when returning from background after long idle.
- May keep short-lived in-memory copies; respect Cache-Control when using HTTP caches.
- Do not treat cached chapter JSON as offline entitlement.

---

## 24. API master table

### Mobile / public APIs (Flutter may call)

| Method | Endpoint | Auth | Purpose | Mobile |
| ------ | -------- | ---- | ------- | ------ |
| GET | `/api/v1/health` | None | Liveness | Optional |
| POST | `/api/v1/auth/google` | None | Google Sign-In → access token | Yes |
| GET | `/api/v1/app-config` | None | Remote config | Yes |
| GET | `/api/v1/announcements` | None | Published announcements | Yes |
| GET | `/api/v1/media/covers/:id` | None | Cover image bytes | Yes (via URL) |
| GET | `/api/v1/books` | None | Catalogue | Yes |
| GET | `/api/v1/books/:id` | None | Book details | Yes |
| GET | `/api/v1/books/:bookId/chapters` | None | Chapter list (no content) | Yes |
| GET | `/api/v1/books/:bookId/chapters/:chapterId` | Optional Bearer | Chapter content | Yes |
| POST | `/api/v1/payments/create-order` | Bearer user | Start purchase | Yes |
| POST | `/api/v1/payments/verify` | Bearer user | Confirm purchase | Yes |
| GET | `/api/v1/payments/:orderId/status` | Bearer user | Payment/entitlement status | Yes |
| GET | `/api/v1/library` | Bearer user | Owned books | Yes |

### Server-only (not Flutter)

| Method | Endpoint | Notes |
| ------ | -------- | ----- |
| POST | `/api/v1/payments/webhook` | Razorpay only — **DO NOT CALL FROM FLUTTER** |

### Admin-only (DO NOT CALL FROM FLUTTER)

| Method | Endpoint | Purpose |
| ------ | -------- | ------- |
| POST | `/api/v1/auth/admin/login` | Admin login |
| POST | `/api/v1/auth/admin/refresh` | Admin refresh |
| GET | `/api/v1/auth/admin/me` | Admin profile |
| POST | `/api/v1/auth/admin/logout` | Admin logout |
| GET | `/api/v1/admin/dashboard` | Dashboard KPIs |
| GET | `/api/v1/admin/audit-logs` | Audit trail |
| GET | `/api/v1/admin/app-config` | Admin config |
| PATCH | `/api/v1/admin/app-config` | Update config |
| GET/POST | `/api/v1/admin/announcements` | Manage announcements |
| GET/PATCH/DELETE | `/api/v1/admin/announcements/:id` | Announcement CRUD |
| POST | `/api/v1/admin/announcements/:id/publish` | Publish |
| POST | `/api/v1/admin/announcements/:id/unpublish` | Unpublish |
| POST | `/api/v1/admin/announcements/:id/archive` | Archive |
| GET | `/api/v1/admin/users` | Customers list |
| GET | `/api/v1/admin/users/:id` | Customer detail |
| GET | `/api/v1/admin/purchases` | Purchases |
| GET | `/api/v1/admin/purchases/:id` | Purchase detail |
| GET | `/api/v1/admin/payments` | Payments |
| GET | `/api/v1/admin/payments/:id` | Payment detail |
| GET | `/api/v1/admin/entitlements` | Entitlements |
| GET | `/api/v1/admin/entitlements/:id` | Entitlement detail |
| GET | `/api/v1/admin/refunds` | Refunds |
| POST | `/api/v1/admin/covers` | Cover upload |
| POST/GET/PATCH/DELETE | `/api/v1/admin/books...` | Book admin lifecycle |
| POST/GET | `/api/v1/admin/books/:bookId/chapters` | Chapter create/list |
| POST/GET/PATCH/DELETE | `/api/v1/admin/chapters/:id...` | Chapter admin |
| POST | `/api/v1/admin/books/:bookId/import` | Document import |
| GET | `/api/v1/admin/document-imports/:id` | Import status |

---

## 25. Mobile happy path (adapted to implementation)

```text
App Launch
 ↓
GET /app-config
 ↓
Evaluate appUpdate (client-side)
 ↓
GET /announcements
 ↓
Determine Guest vs stored accessToken
 ↓
Home (branding + featuredBooks)
 ↓
GET /books (filters from catalogue config)
 ↓
GET /books/:id
 ↓
GET /books/:bookId/chapters
 ↓
 ┌────────────────────────────┐
 │ FREE                       │
 │ Guest allowed? (app-config)│
 └────────────┬───────────────┘
              ↓
 GET chapter (optional/required auth)
              ↓
 Render Rich Text V1
              │
 ┌────────────┴───────────────┐
 │ PAID                       │
 └────────────┬───────────────┘
              ↓
        Google login if needed
              ↓
     POST /payments/create-order
              ↓
        Razorpay Checkout
              ↓
     POST /payments/verify
              ↓
     (optional) GET status / GET library
              ↓
     GET paid chapter content
              ↓
 Progress / Bookmarks APIs → NOT IMPLEMENTED
 (local-only UX only if product accepts non-synced state)
```

---

## 26. Demo / Happy Path QA Checklist

### Authentication

- [ ] Google login returns `accessToken` + user
- [ ] Bearer token authorizes library / payments
- [ ] Invalid/expired token → 401; app returns to login
- [ ] Logout is **local token clear only** (no mobile logout API)
- [ ] Token refresh API unavailable — re-auth required after expiry

### Catalogue

- [ ] Books load (published only)
- [ ] Language filter `ta` / `en` / `hi`
- [ ] Search by title/author
- [ ] Book details load
- [ ] FREE vs PAID distinction clear
- [ ] Draft/unpublished/archived never appear

### Payment

- [ ] Create order returns `orderId`, `amount`, `currency`, `keyId`
- [ ] Razorpay Checkout completes
- [ ] Verify returns `entitled: true` when captured
- [ ] Library lists LIFETIME entitlement
- [ ] Paid chapter unlocks; unauthorized still 403

### Reader

- [ ] Chapter list without content
- [ ] Rich Text V1 renders (paragraph, heading, lists, quote, marks)
- [ ] Chapter navigation by list order / chapterNumber
- [ ] Progress save/restore via API → **blocked / NOT IMPLEMENTED**
- [ ] Bookmark create/delete via API → **blocked / NOT IMPLEMENTED**

### Remote config

- [ ] Branding colors / name load
- [ ] Featured books
- [ ] Announcements (or empty when disabled)
- [ ] Feature flags present
- [ ] App update fields drive optional/force UI

### Security

- [ ] Unauthorized paid chapter → `PURCHASE_REQUIRED`
- [ ] No admin credentials in app
- [ ] No Razorpay secret in app
- [ ] No offline full-book cache

---

## 27. Known Limitations / Reserved Features

| Item | Status |
| ---- | ------ |
| Mobile `POST /auth/refresh` | **NOT IMPLEMENTED** |
| Mobile `POST /auth/logout` | **NOT IMPLEMENTED** |
| Mobile `GET /me` | **NOT IMPLEMENTED** |
| Progress HTTP APIs | **NOT IMPLEMENTED** (model only) |
| Bookmark HTTP APIs | **NOT IMPLEMENTED** (model + position contract only) |
| Paid book preview reading | **RESERVED / NOT IMPLEMENTED** |
| Offline reading / downloads | **NOT IMPLEMENTED** (online-only policy) |
| Media blocks beyond Rich Text V1 types | **NOT IMPLEMENTED** |
| Backend forced API block by app version | **NOT IMPLEMENTED** (client evaluates `appUpdate`) |
| Document import / PDF-DOCX as reader format | Admin import only; mobile reads Rich Text JSON |
| App-store publishing automation | Out of scope |

---

## 28. Documentation Notes

### Discrepancies vs older docs

1. Previous `docs/MOBILE_APP_INTEGRATION.md` stated only `GET /health` existed. That is **obsolete**; this file replaces it with the implemented surface.
2. `docs/API.md` still emphasizes foundational/admin material; if it conflicts with this file on mobile behavior, **prefer this document** and the live route registration under `backend/src/routes` + module routers.
3. App-config feature flags for bookmarks/progress may be `true` while mobile APIs are absent — flags must not be read as “API exists.”
4. Example production URLs in `frontend/.env.example` / README are deployment examples, not Flutter constants.

### Secrets

This document intentionally omits JWT secrets, cookie secrets, Google client secrets, Razorpay secrets, webhook secrets, and database credentials.

---

## 29. Health (optional)

```http
GET /api/v1/health
```

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "service": "mantirigam-admin-api"
  }
}
```

Useful for connectivity checks; not a product feature API.

---

*Generated from the Mantirigam Admin backend implementation. Flutter work belongs in the separate `mantirigam` repository using this file as the contract.*
