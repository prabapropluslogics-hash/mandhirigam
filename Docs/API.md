# API

## Project title

Mantirigam Admin

## Purpose

This document lists the HTTP APIs that currently exist. It does not describe planned feature endpoints.

## Base path

```text
/api/v1
```

The local base URL comes from environment configuration. The checked-in example is `http://localhost:5050/api/v1` because port `5000` is often occupied. Application code does not hardcode that URL.

## Response envelope

Success:

```json
{
  "success": true,
  "data": {}
}
```

Error:

```json
{
  "success": false,
  "error": {
    "code": "SOME_ERROR_CODE",
    "message": "Human readable message"
  }
}
```

## Implemented endpoints

### Health

```http
GET /api/v1/health
```

Returns HTTP 200 when the API process is running.

```json
{
  "success": true,
  "data": {
    "status": "ok",
    "service": "mantirigam-admin-api"
  }
}
```

## Foundation error behavior

Unknown routes return HTTP 404:

```json
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "Route not found: METHOD /path"
  }
}
```

Invalid JSON bodies return HTTP 400 with code `INVALID_JSON`.

Unexpected failures return HTTP 500 with code `INTERNAL_ERROR`. Production responses do not include internal error details.

### Admin login

```http
POST /api/v1/auth/admin/login
```

Accepts an email and password. On success, sets HTTP-only session cookies and returns the public admin profile. Invalid credentials always return `Invalid email or password`.

### Current admin

```http
GET /api/v1/auth/admin/me
```

Requires a valid admin session. Returns `id`, `email`, and `name`. Never returns `passwordHash`.

### Refresh session

```http
POST /api/v1/auth/admin/refresh
```

Rotates the refresh credential and issues a new short-lived access token. The previous refresh session is revoked.

### Admin logout

```http
POST /api/v1/auth/admin/logout
```

Revokes the current refresh session and clears authentication cookies. This is an admin session logout. It does not revoke a Google account session.

### Google mobile sign-in

```http
POST /api/v1/auth/google
```

Public and rate limited. Accepts only `{ "idToken": "<GOOGLE_ID_TOKEN>" }`. The backend verifies that Google ID token with `google-auth-library` before trusting any identity. Verification checks the signature, issuer (`https://accounts.google.com` or `accounts.google.com`), audience (`GOOGLE_CLIENT_ID`), and expiration. The verified `sub` is the only Google identity key. Email is required and must have `email_verified === true`. The Google token is not stored, logged, or returned.

A matching `googleSubjectId` updates safe profile fields and `lastLoginAt`, then the API issues the existing Mantirigam mobile access JWT. A new `sub` creates an `ACTIVE` user. The same email with a different or missing `googleSubjectId` returns `GOOGLE_ACCOUNT_CONFLICT` and is not linked or overwritten. An `INACTIVE` user is rejected. There is no mobile refresh or logout endpoint; admin refresh and logout are unchanged. The Google ID token is not an application session and cannot call mobile APIs.

Application JWT claims remain `sub` (internal user id), `type`, issuer `mantirigam-admin-api`, audience `mantirigam-user`, and the configured expiry. Algorithm is `HS256`.

## Pagination and search

List responses that are paginated use this envelope. `pagination` is a sibling of `data`, not nested inside it.

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

`page` defaults to 1. `limit` defaults to 20 and is capped at 50. Invalid pagination values fall back to those defaults. Results are sorted by `updatedAt` descending, then `_id` descending.

Search is optional, trimmed, limited to 80 characters, and matched as an escaped case-insensitive substring against title and author. Arbitrary client input is not interpolated as a raw regular expression.

## Admin users

`GET /api/v1/admin/users` and `GET /api/v1/admin/users/:id` require an active admin session. They are read-only. A missing session returns HTTP 401. A mobile-user JWT is rejected. An unknown or invalid user id returns HTTP 404 with code `USER_NOT_FOUND`.

The list accepts `page`, `limit` (maximum 50), `search` (name or email only), and `status` (`ACTIVE` or `INACTIVE`). Results are newest first by `createdAt`. Search is escaped and is not matched against Google subject ids.

The detail response includes the account, successful purchases using the stored purchase amount, entitlements, a bounded payment history, a bounded reading summary, and a bookmark count. Login history is limited to the existing `lastLoginAt` field. The payload does not include `googleSubjectId`, tokens, password hashes, gateway ids, or raw gateway metadata. If a Google subject is stored, the UI provider label is `Google`; the subject itself is not returned.

## Admin commerce

These admin-only read endpoints require an active admin session. They do not accept a mobile-user JWT. They do not create, refund, or mutate purchases, payments, or entitlements. Refund initiation is intentionally not available in the Admin UI in this version. Settlement, payout, and GST reporting are not implemented because the current data model does not contain authoritative settlement or tax data.

```http
GET /api/v1/admin/purchases
GET /api/v1/admin/purchases/:id
GET /api/v1/admin/payments
GET /api/v1/admin/payments/:id
GET /api/v1/admin/entitlements
GET /api/v1/admin/entitlements/:id
GET /api/v1/admin/refunds
```

List endpoints accept `page` and `limit` (maximum 50). Search matches customer name, customer email, or book title in the database. Matching is not capped at a fixed number of customers or books; only the requested page of commerce records is returned. Purchase and payment search can also match a stored operational reference, but gateway order ids and raw webhook metadata are not returned. Amounts remain integer minor units. Historical purchase and payment amounts are not recalculated from the current book price.

`GET /api/v1/admin/purchases` also accepts `status` (`PENDING`, `SUCCESS`, `FAILED`, `REFUNDED`), `bookId`, `userId`, `dateFrom`, and `dateTo`. Results are ordered by `purchasedAt` descending, then `createdAt` and `_id`. An unknown id returns `PURCHASE_NOT_FOUND`.

`GET /api/v1/admin/payments` accepts the same date and party filters, with payment statuses `CREATED`, `AUTHORIZED`, `CAPTURED`, `FAILED`, and `REFUNDED`. A stored gateway payment id may be shown as an operational reference. Raw metadata and gateway order ids are omitted. An unknown id returns `PAYMENT_NOT_FOUND`.

`GET /api/v1/admin/entitlements` accepts `status` (`ACTIVE`, `REVOKED`), `source` (`RAZORPAY`, `ADMIN`), `userId`, `bookId`, and `search`.

`GET /api/v1/admin/entitlements/:id` is read-only. It returns the access record, customer, and book, plus a related purchase and payment only when those records already exist for the same customer and book. Missing related records are omitted rather than invented. An unknown id returns `ENTITLEMENT_NOT_FOUND`. The response does not include Google subject ids, tokens, password hashes, gateway order ids, webhook payloads, or raw payment metadata. There is no revoke or create action.

`GET /api/v1/admin/refunds` lists purchases whose stored status is `REFUNDED`. It is read-only. There is no admin refund creation endpoint. The refund amount is the stored purchase amount. The timestamp is the purchase `updatedAt` from the existing refund webhook flow, not a separately invented refund ledger.

## Mobile app configuration

Remote configuration controls presentation and approved product behavior only. It does not control authentication, authorization, payment verification, reader security, API security, or other security-critical architecture.

`GET /api/v1/admin/app-config` and `PATCH /api/v1/admin/app-config` require an active admin session. `GET /api/v1/app-config` is public so the mobile app can read published configuration before login. The public response is built explicitly. It does not return `updatedBy`, admin ids, audit data, secrets, or the raw Mongo document.

The admin payload replaces the stored configuration. The server owns the integer `version` and increments it on each successful save. The submitted `version` must match the current version or the update returns `APP_CONFIG_CONFLICT`.

Hex colors must be `#RRGGBB`. Optional URLs must be HTTPS. Default catalogue language is `all`, `ta`, `en`, or `hi`. Featured books are published books only, unique, and limited to 10.

The Admin configures update policy; it does not publish mobile binaries. The canonical `appUpdate` schema is:

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

Versions use stable `major.minor.patch` only, compared numerically (`1.9.9` is older than `1.10.0`). `minimumVersion` is the oldest version allowed to continue. `latestVersion` is the recommended version. A version below the minimum should be treated by the mobile app as a required update. A version at or above the minimum and below the latest is an optional update. A version at or above the latest needs no update. Equal minimum and latest values are valid. A platform store URL is required when both versions are set, because users below the minimum need a destination. URLs must be HTTPS. `updateMessage` is optional plain text up to 280 characters. `forceUpdateEnabled` means a required update should be presented as mandatory when the installed version is below the minimum. It does not force the binary to update and does not block API access. Actual Play Store and App Store publishing remains outside this Admin.

Older stored documents that used `latestAndroidVersion`, `minimumAndroidVersion`, `androidStoreUrl`, and the matching iOS fields are normalized into this schema on read. New writes store only the nested schema.

Guest free-book reading uses `AppSetting` key `ALLOW_GUEST_FREE_BOOK_READING` as the only source of truth. The mobile configuration screen reads and writes that setting. Paid book preview is not implemented. `ALLOW_PAID_BOOK_PREVIEW` remains `false`, and a request that tries to enable it is rejected.

Public featured books are returned as `{ id, title }` for published books only.

`features.announcementsEnabled` is the only announcement control in app config. Announcement content is owned by the Announcement entity. Mobile App Configuration controls announcement visibility only. The public app-config response does not include announcement title, message, or action fields.

## Announcements

Announcement content is owned by the Announcement entity. Mobile App Configuration controls announcement visibility only.

Admin endpoints require an active admin session:

```text
POST   /api/v1/admin/announcements
GET    /api/v1/admin/announcements
GET    /api/v1/admin/announcements/:id
PATCH  /api/v1/admin/announcements/:id
DELETE /api/v1/admin/announcements/:id
POST   /api/v1/admin/announcements/:id/publish
POST   /api/v1/admin/announcements/:id/unpublish
POST   /api/v1/admin/announcements/:id/archive
```

The list accepts `search`, `status`, `page`, and `limit` (default 20, maximum 50). Search matches title and message in the database. Results are ordered by `displayOrder` ascending, then `createdAt` descending, then `_id` descending. A lower display order is higher priority. Duplicate display orders are allowed and do not break ordering.

Create always stores `DRAFT`. The client cannot set status directly. Draft, published, and unpublished announcements can be edited. Archived announcements are read-only.

Publish accepts draft or unpublished records and sets `publishedAt`. Publishing an already published announcement is a no-op. Unpublished preserves the historical `publishedAt`. Archive accepts draft, published, and unpublished records. Archived announcements cannot be published or edited. Delete physically removes a draft, archives an unpublished announcement, rejects a published announcement, and is a no-op for an already archived announcement.

`GET /api/v1/announcements` is public. It returns at most 10 published announcements, using the same order, and only the fields `id`, `title`, `message`, `imageUrl`, `actionLabel`, `actionUrl`, `displayOrder`, and `publishedAt`. Image and action URLs must be HTTPS. Title and message are plain text. There is no scheduling and no revision history beyond `publishedAt`, `createdAt`, and `updatedAt`.

If `features.announcementsEnabled` is false, the public announcements endpoint returns an empty list. Stored published announcements are not deleted or unpublished. The response uses `Cache-Control: public, max-age=60`.

## Audit logs

`GET /api/v1/admin/audit-logs` requires an active admin session. It is read-only. There is no admin route to create, edit, delete, or clear audit logs. Audit log retention and automatic deletion are not implemented in V1.

The list accepts `search`, `actorType` (`ADMIN`, `SYSTEM`), `action`, `entityType`, `dateFrom`, `dateTo`, `page`, and `limit` (default 20, maximum 50). Results are ordered by `createdAt` descending, then `_id`. Search matches admin name or email, book, chapter, announcement, or user display names, and common action words in the database. It does not require a raw Mongo id.

The response returns `actor.type`, `actor.name`, `action`, `entity.type`, `entity.label`, sanitized `metadata`, and `createdAt`. Entity labels use titles or names when the record still exists, otherwise `Deleted or unavailable`. `APP_SETTING` is labeled Mobile App Settings. Metadata is allowlisted to `changedFields`, `from`, `to`, `reason`, `source`, and `safeReference`. Password hashes, tokens, Google subject ids, webhook payloads, and arbitrary nested documents are not returned.

Indexes support recent activity and the admin filters: `createdAt`, `actorType + createdAt`, `action + createdAt`, and `entityType + createdAt`.

## Admin dashboard

`GET /api/v1/admin/dashboard` requires `authenticateAdmin`. A missing or invalid admin session returns HTTP 401. A mobile-user JWT is not an admin session and is rejected. An inactive admin is rejected with HTTP 403.

The endpoint is read-only. It returns current counts and recent lists. It does not create analytics documents.

```text
grossSales = sum of purchase.amount where status is SUCCESS
```

Successful purchase amounts are historical minor units stored on the purchase. Revenue is not recalculated from the current book price. Refunded purchases are excluded from `grossSales` and counted separately in `refundedPurchases`. This is gross sales, not a tax or settlement figure.

```text
newUsersThisMonth = users whose createdAt is on or after the start of the current UTC calendar month
```

`publishedBooks` counts books with `status = PUBLISHED`. `activeEntitlements` counts entitlements with `status = ACTIVE`. Recent purchases, users, and audit activity are limited lists. The payload does not include payment gateway secrets, Google tokens, or raw MongoDB ids.

## Admin book management

All admin book and chapter endpoints require `authenticateAdmin`. A missing or invalid admin session returns HTTP 401 with code `UNAUTHENTICATED`.

New books are always created as `DRAFT`. Clients cannot set `status`, `publishedAt`, `_id`, `createdAt`, or `updatedAt`. The server owns timestamps.

Price is an integer in minor units. Currency is `INR`. Language is `ta`, `en`, or `hi`. `FREE` books must have price `0`. `PAID` books must have price greater than `0`.

```http
POST   /api/v1/admin/books
GET    /api/v1/admin/books
GET    /api/v1/admin/books/:id
PATCH  /api/v1/admin/books/:id
DELETE /api/v1/admin/books/:id
POST   /api/v1/admin/books/:id/publish
POST   /api/v1/admin/books/:id/unpublish
POST   /api/v1/admin/books/:id/archive
```

`GET /api/v1/admin/books` accepts `page`, `limit`, `search`, `language`, `accessType`, and `status`.

`DELETE` archives the book. It does not remove the document.

Create body:

```json
{
  "title": "Example Book",
  "description": "Book description",
  "author": "Author Name",
  "language": "ta",
  "coverImage": "https://example.com/cover.jpg",
  "accessType": "PAID",
  "price": 29900,
  "currency": "INR",
  "previewEnabled": false,
  "previewConfig": {
    "type": "NONE"
  }
}
```

Controlled update fields are `title`, `description`, `author`, `language`, `coverImage`, `accessType`, `price`, `currency`, `previewEnabled`, and `previewConfig`.

`POST /api/v1/admin/covers` uploads a JPEG, PNG, or WebP cover of at most 2 MB and returns a public `coverImage` URL. The image is served at `GET /api/v1/media/covers/:id`. The book record still stores only that URL.

A publish request succeeds only when the title, language, access type, and price rules are valid, at least one chapter exists, and at least one chapter is `PUBLISHED`. Publishing sets `status` to `PUBLISHED` and `publishedAt` to the current time. Otherwise the API returns HTTP 422 with code `BOOK_NOT_PUBLISHABLE`.

Unpublish sets `status` to `UNPUBLISHED` and does not revoke existing entitlements or rewrite purchases. Archive sets `status` to `ARCHIVED`. Archived books are omitted from the public catalogue.

Important book error codes: `BOOK_NOT_FOUND` (404), `INVALID_BOOK_DATA` (400), `BOOK_NOT_PUBLISHABLE` (422), `BOOK_ALREADY_ARCHIVED` (409).

## Public book catalogue

These endpoints do not require authentication. They return only `PUBLISHED` books. Draft, unpublished, and archived books are not returned.

```http
GET /api/v1/books
GET /api/v1/books/:id
```

`GET /api/v1/books` accepts `page`, `limit`, `language`, `accessType`, and `search`.

Public book fields are `id`, `title`, `description`, `author`, `language`, `coverImage`, `accessType`, `price`, `currency`, `previewEnabled`, `previewConfig`, `status`, and `publishedAt`. Admin timestamps, audit data, payment data, and entitlement data are not included.

A missing or non-published book returns HTTP 404 with code `BOOK_NOT_FOUND`.

## Admin chapter management

Admin chapter endpoints require `authenticateAdmin`.

```http
POST   /api/v1/admin/books/:bookId/chapters
GET    /api/v1/admin/books/:bookId/chapters
GET    /api/v1/admin/chapters/:id
PATCH  /api/v1/admin/chapters/:id
DELETE /api/v1/admin/chapters/:id
POST   /api/v1/admin/chapters/:id/publish
POST   /api/v1/admin/chapters/:id/unpublish
POST   /api/v1/admin/chapters/:id/retire
GET    /api/v1/admin/chapters/:id/dependencies
```

The parent book must exist and must not be `ARCHIVED`. New chapters are `DRAFT`. Clients cannot set `status` or change `bookId`. `contentFormat` must be `RICH_TEXT`. `content` must match Rich Text V1 or V2 (see `docs/RICH_TEXT_V2.md`). `chapterNumber` must be a positive integer and unique within the book.

The list endpoint orders chapters by `chapterNumber` ascending and omits full `content`. `GET /api/v1/admin/chapters/:id` returns full content. Admin chapter responses include a safe parent `book` summary with `id`, `title`, `language`, `accessType`, `price`, `status`, and optional `coverImage`. The chapter still owns only `bookId`. Clients cannot re-parent a chapter.

A chapter can be published only when its book exists, the book is not `ARCHIVED`, the title is valid, `contentFormat` is `RICH_TEXT`, and the content is valid. Rich Text V2 publishing additionally requires `ALLOW_RICH_TEXT_V2_PUBLISH=true`. Publishing does not publish the parent book. Unpublishing a chapter does not unpublish the parent book.

`DELETE` hard-deletes only unreferenced `DRAFT`/`UNPUBLISHED` chapters (no bookmarks/progress). Otherwise use `POST .../retire`. A `PUBLISHED` chapter returns HTTP 409 with code `CHAPTER_MUST_BE_UNPUBLISHED`. Retirement preserves bookmarks, progress, and media references.

Important chapter error codes: `CHAPTER_NOT_FOUND` (404), `INVALID_CHAPTER_DATA` (400), `DUPLICATE_CHAPTER_NUMBER` (409), `CHAPTER_NOT_PUBLISHABLE` (422), `CHAPTER_MUST_BE_UNPUBLISHED` (409), `CHAPTER_HAS_DEPENDENCIES` (409), `CHAPTER_ALREADY_RETIRED` (409), `RICH_TEXT_V2_PUBLISH_DISABLED` (409), `BOOK_NOT_FOUND` (404), `BOOK_ALREADY_ARCHIVED` (409).

## Public chapter access

```http
GET /api/v1/books/:bookId/chapters
GET /api/v1/books/:bookId/chapters/:chapterId
```

The book and chapter must both be `PUBLISHED`. Otherwise these endpoints return HTTP 404.

The chapter list returns published chapter metadata only. It does not return full content.

Public catalogue responses may include `accessType`, `price`, and `currency`. They do not include user-specific purchase or entitlement state.

Full chapter content for a published `FREE` book follows `ALLOW_GUEST_FREE_BOOK_READING`. If the setting is missing or not `true`, the default is `false` and an unauthenticated request returns HTTP 401 with code `AUTHENTICATION_REQUIRED`. An authenticated mobile user may read a free chapter when guest reading is off. This value is read from `AppSetting`; it is not hardcoded in the access rule.

`PAID` books return full chapter content only when the request has a valid mobile user token and that user has an `ACTIVE` lifetime entitlement for the book. Otherwise the chapter endpoint returns HTTP 403 with code `PURCHASE_REQUIRED`. Purchase records alone do not grant access. Paid preview is not implemented. A lifetime entitlement covers chapters added later; no additional purchase is required.

## Payments

One-time purchase only. There are no subscriptions and no recurring payments.

```http
POST /api/v1/payments/create-order
POST /api/v1/payments/verify
GET  /api/v1/payments/:orderId/status
POST /api/v1/payments/webhook
GET  /api/v1/library
```

`create-order`, `verify`, `status`, and `library` require a mobile user Bearer token. They do not accept the admin cookie or an admin JWT. There is no endpoint that mints a mobile user token. The client may send only `bookId` when creating an order. Any other field is rejected. The server uses the published book price.

A book can be ordered only when it is `PUBLISHED`, `PAID`, and priced above zero. An existing `ACTIVE` entitlement returns HTTP 409 `BOOK_ALREADY_OWNED` and does not create another order. At most one `PENDING` purchase and one `SUCCESS` purchase exist per user and book. A repeated create-order while a purchase is still `PENDING` returns that existing order instead of creating another Razorpay order. A successful first create-order call creates a `PENDING` purchase and a `CREATED` payment. It does not create an entitlement. The response includes the public Razorpay `keyId`, order id, amount, and currency. It never includes the key secret or webhook secret.

`verify` checks the Razorpay HMAC SHA256 signature of `orderId|paymentId` with `RAZORPAY_KEY_SECRET`, then loads the stored payment and confirms the captured payment with the gateway. Invalid signatures, unknown orders, cross-user orders, amount mismatches, currency mismatches, and non-captured states do not grant access. A captured payment sets the purchase to `SUCCESS` and creates one `ACTIVE` `LIFETIME` entitlement. Repeating verification returns that same state.

The webhook is not JWT-authenticated. Express keeps the raw body only for `POST /api/v1/payments/webhook`. The signature is `X-Razorpay-Signature` using `RAZORPAY_WEBHOOK_SECRET`. A missing, invalid, or mismatched signature returns HTTP 400 `INVALID_WEBHOOK_SIGNATURE`. `payment.captured` fulfills the same purchase and entitlement path. `payment.failed` cannot downgrade a captured payment, a successful purchase, or an active entitlement. A refund event revokes access only when that event's amount equals the stored payment amount and the payment is still `CAPTURED`. A refund whose amount is less than the stored payment is treated as partial and does not revoke the lifetime entitlement. A refund that cannot yet be linked to a stored payment is not marked processed, so a later delivery can still apply it. Unknown or partial refunds do not affect another user. A repeated full refund is idempotent. Unknown events are acknowledged and ignored. Processed event ids are stored so retries do not duplicate records. Historical purchase amounts are not changed when a book price changes.

`GET /api/v1/payments/:orderId/status` returns only the authenticated user's payment. `GET /api/v1/library` returns that user's active entitled books, without chapter content, using the standard pagination envelope.

Payment error codes: `BOOK_NOT_FOUND`, `BOOK_NOT_PURCHASABLE`, `BOOK_ALREADY_OWNED`, `INVALID_PAYMENT_SIGNATURE`, `PAYMENT_NOT_FOUND`, `PAYMENT_OWNERSHIP_MISMATCH`, `PAYMENT_AMOUNT_MISMATCH`, `PAYMENT_CURRENCY_MISMATCH`, `PAYMENT_NOT_CAPTURED`, `INVALID_WEBHOOK_SIGNATURE`, `PAYMENT_VERIFICATION_FAILED`, `PURCHASE_REQUIRED`.

## Document import

Admin only. The book must exist and must not be `ARCHIVED`.

```http
POST /api/v1/admin/books/:bookId/import
GET  /api/v1/admin/document-imports/:id
```

`POST` accepts `multipart/form-data` with a `file` field and optional `title` / `targetChapterId` fields. Supported sources are PDF (`application/pdf`, `.pdf`) and DOCX (`application/vnd.openxmlformats-officedocument.wordprocessingml.document`, `.docx`). The server checks the extension and the file signature. It does not trust the filename or client MIME type alone.

The default upload limit is 25 MB, configured with `DOCUMENT_MAX_UPLOAD_MB`. Oversized uploads return HTTP 413 `DOCUMENT_TOO_LARGE`.

A successful start returns HTTP 202:

```json
{
  "success": true,
  "data": {
    "importId": "...",
    "status": "PROCESSING",
    "createdChapterIds": []
  }
}
```

Poll `GET /api/v1/admin/document-imports/:id` for progress (`totalPages`, `completedPages`, `ocrPages`, `currentPage`, `imageCount`, `warnings`, `pagePreviewMediaIds`, `contentVersion`).

PDF imports produce one Rich Text V2 draft chapter with interleaved image blocks (or update `targetChapterId` when provided). DOCX without images may still produce V1. Chapters are never auto-published. Image binaries are stored via the media service (`chapter_image`); Admin-only page previews use `import_page_preview`.

Extraction is not guaranteed to be 100% accurate. Administrator review is mandatory before publication. OCR uses the existing Poppler + Tesseract path when Tamil/text quality gates select it.

Important error codes: `DOCUMENT_REQUIRED` (400), `UNSUPPORTED_DOCUMENT_TYPE` (400), `DOCUMENT_TOO_LARGE` (413), `BOOK_NOT_FOUND` (404), `BOOK_ARCHIVED` (409), `IMPORT_ALREADY_PROCESSING` (409), `CHAPTER_NOT_EDITABLE` (409), `PDF_TEXT_EXTRACTION_FAILED` (422), `DOCX_TEXT_EXTRACTION_FAILED` (422), `DOCUMENT_IMPORT_FAILED` (422).

`GET /api/v1/admin/document-imports/:id` returns import status without temporary filesystem paths.

## Audit logging

Admin book mutations write `AuditLog` records with `actorType` `ADMIN` and the authenticated admin id. Book actions are `CREATE`, `UPDATE`, `PUBLISH`, `UNPUBLISH`, `ARCHIVE`, `PRICE_CHANGE`, and `DOCUMENT_IMPORT`. Chapter actions are `CREATE`, `UPDATE`, `PUBLISH`, `UNPUBLISH`, and `DELETE`.

A paid price change also writes `PRICE_CHANGE` metadata with `oldPrice`, `newPrice`, and `currency`. Audit metadata does not include passwords, tokens, or payment secrets. An audit write failure fails the request; it is not ignored.

## Current implementation status

See also `docs/RICH_TEXT_V2.md` for the V2 schema, entitled chapter-image access, and Flutter pending work.

See also `docs/ORIGINAL_PDF_READER.md` for Original PDF Reader mode, `chapter_pdf` storage, Range download, and `ALLOW_ORIGINAL_PDF_PUBLISH`.

Document import creates draft Rich Text V1 or V2 chapters. Extraction is not guaranteed to be 100% accurate. Administrator review is mandatory before publication. Flutter V2 image rendering and Flutter PDF viewing remain pending in the separate mobile repository.
