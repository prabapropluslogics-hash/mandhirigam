# Flutter implementation notes

This document describes what the `maanthirigam` Flutter app actually implements against `Docs/MOBILE_APP_INTEGRATION.md`. It is not a replacement for that contract.

## Architecture

Existing design system, dark charcoal/gold UI, `MainShell` tabs, and named routes were kept.

Added layers:

```text
UI screens
  → Provider controllers
    → repositories
      → API services
        → ApiClient (http)
```

### Folders

- `lib/core/` — env, HTTP client, envelope, errors, secure storage, branding
- `lib/data/models|services|repositories/` — backend DTOs and API calls
- `lib/state/` — auth, app-config, catalogue, library, payment
- `lib/features/` — splash, auth, home, catalogue, book, reader, library, profile, payment

State management: **Provider**.

## Environment

```text
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5050/api/v1 --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

Physical device: use the computer LAN IP instead of `10.0.2.2`.

Production: pass an `https://…/api/v1` URL. Do not put JWT, Razorpay secret, webhook secret, Google client secret, or Mongo credentials in Flutter.

Default development base URL: `http://10.0.2.2:5050/api/v1`.

## Implemented endpoints

- `GET /api/v1/app-config`
- `GET /api/v1/announcements`
- `POST /api/v1/auth/google`
- `GET /api/v1/books`
- `GET /api/v1/books/:id`
- `GET /api/v1/books/:bookId/chapters`
- `GET /api/v1/books/:bookId/chapters/:chapterId`
- `POST /api/v1/payments/create-order`
- `POST /api/v1/payments/verify`
- `GET /api/v1/payments/:orderId/status`
- `GET /api/v1/library`

Health is not called.

## Auth

Google Sign-In SDK → Google ID token → `POST /auth/google` → Mantirigam `accessToken` stored in Keychain / EncryptedSharedPreferences.

Local logout only. No refresh and no `/me`. `401 TOKEN_EXPIRED|TOKEN_INVALID|UNAUTHENTICATED` clears the session and opens login.

## Payment

Create-order amount/key/orderId open Razorpay. Checkout success is not ownership. `POST /payments/verify` is authoritative. Interrupted checkout can use payment status. `BOOK_ALREADY_OWNED` refreshes library.

## Reader

Rich Text V1 widgets keyed by `block.id`. Previous/Next use ordered `chapterNumber`. Reader enables Android `FLAG_SECURE`. Paid content is requested from the backend; `PURCHASE_REQUIRED` shows purchase UI.

## Remote config

Branding colors, hero, featured refs, catalogue filters, guest free-reading, announcements, and store update prompts come from app-config. Continue-reading is not shown because progress APIs are not implemented.

## Not implemented (contract)

Mobile refresh, mobile logout, `/me`, progress APIs, bookmark APIs, paid preview, offline reading, PDF/DOCX, admin APIs.

## Run / test

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=API_BASE_URL=https://HOST/api/v1 --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

This machine: `flutter analyze` passed. `flutter test` and `flutter build apk --release` were blocked by Windows Application Control (`flutter_tester.exe`, `gen_snapshot.EXE`, `font-subset.exe`). iOS release build requires macOS.

Google Sign-In on Android needs a Web client ID as `GOOGLE_SERVER_CLIENT_ID`. iOS also needs `GIDClientID` and the reversed client URL scheme in `Info.plist`.
