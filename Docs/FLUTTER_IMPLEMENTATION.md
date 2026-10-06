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
# Optional: Android reads the Web client ID from google-services.json
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>
```

Default API base URL: `https://mandhirigam-admin.onrender.com/api/v1`.

Local emulator against a PC backend:

```text
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5050/api/v1
```

Do not put JWT, Razorpay secret, webhook secret, Google client secret, or Mongo credentials in Flutter.

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

Google Sign-In SDK → Google ID/access token → Firebase Authentication (`signInWithCredential`) → `POST /auth/google` with the Google ID token → Mantirigam `accessToken` stored in Keychain / EncryptedSharedPreferences.

A session is valid only when both the Firebase user and the Mantirigam token exist; any mismatch on restore, or a failed backend exchange, signs out of both. Firebase dropping its user (disabled / revoked) ends the app session. The stored `UserProfile` carries `firebaseUid`.

Firebase is initialized in `bootstrap()` from `android/app/google-services.json` (Google Services Gradle plugin). Android uses its `default_web_client_id` as the Google `serverClientId`; `GOOGLE_SERVER_CLIENT_ID` is only an optional override. The backend `GOOGLE_CLIENT_ID` must be that same Web client ID. iOS needs `ios/Runner/GoogleService-Info.plist` plus the `GIDClientID` / reversed-client-ID URL scheme in `Info.plist` (not yet added).

Local logout only; no `/me`. The backend has no refresh endpoint, so on `401 TOKEN_EXPIRED|TOKEN_INVALID|UNAUTHENTICATED` the `ApiClient` renews the session once (silent Google sign-in → new ID token → `POST /auth/google`) and retries the request. Only if that fails is the session cleared; login then opens on top of the current screen so the user returns to the same place.

Screens that need an account call `requireSignIn` (`features/auth/presentation/require_sign_in.dart`), which pushes login and resolves when the user is back. Cancelling returns to the calling screen.

## Book access

`BookAccess` (`state/book_access.dart`) is the single source for the Book Details CTA: free → "Read now"; paid and owned → "Read now"; paid and not owned → "Buy now". Signing in happens when the button is tapped; "Sign in to …" is never the CTA. Ownership comes from `GET /library` (all pages), loaded whenever the user becomes signed in (startup restore or login) and cleared on logout. Free books need sign-in unless app-config `guestAccess.allowGuestFreeBookReading` is true.

## Payment

Create-order amount/key/orderId open Razorpay. Checkout success is not ownership. `POST /payments/verify` is authoritative; after a verified purchase the book is marked owned and the library reloaded, and the user stays on Book Details, whose CTA becomes "Read now". Cancel shows a snackbar on the same page. Failure / pending opens a sheet with "Try again" / "Check payment status" (payment status endpoint). `BOOK_ALREADY_OWNED` is treated as owned. While an order is created, checkout is open, or verification runs, a non-dismissible progress card follows `PaymentController.phase`; it shows "Test mode" when the backend-provided Razorpay `keyId` starts with `rzp_test_`. Test vs live mode is decided only by the backend keys.

## Reader

Rich Text V1 widgets keyed by `block.id`. Previous/Next and the in-reader chapter list use ordered `chapterNumber`; a slow response for a previously selected chapter is discarded. Reader enables Android `FLAG_SECURE`. Paid content is requested from the backend; `PURCHASE_REQUIRED` shows purchase UI.

Default theme is "Modern Olaichuvadi" (parchment). Text size, line spacing, theme (Olaichuvadi / Dark / Light) and reading width live in `ReaderPreferences` and are stored only on the device (`LocalPreferences`, keys `maanthirigam.pref.*`, which sign-out does not clear). The same controls appear in the reader sheet and in Settings.

Layout (Variation 1 reference): dark chrome with Back, the book title and Share on top. The page is an aged parchment sheet drawn in code (`ReaderSurface`), with burnt uneven edges, rolled ends and a faint palm frond; it has no images. The bottom bar has "≡ Chapter x/N" (the chapter list), round Previous and Next buttons, a Dark/Olaichuvadi toggle and Reading settings. No reading-progress percentage is shown. Share is always shown. Without `APP_SHARE_BASE_URL` it explains that sharing is unavailable and never builds a link.

## Back navigation (Android)

`AppRouter` wraps every pushed route except splash, home and login in `ReturnHomeOnBack` (`lib/routing/back_navigation.dart`). One system back pops to the Home route and selects the Home tab. `MainShell` sends back on the Search, Library or Profile tabs to Home. On Home, the first back shows "Press back again to exit" and a second back within two seconds exits. Login keeps normal back so `requireSignIn` still returns `false` to its caller. On-screen back arrows still go back one step, and iOS keeps swipe-back.

## Sharing and book links

A shared book is `<APP_SHARE_BASE_URL>/book/<bookId>`, e.g.:

```text
flutter build apk --release --dart-define=APP_SHARE_BASE_URL=https://<your-public-domain>
```

`APP_SHARE_BASE_URL` must be the public website origin (https, a real domain). It is never the API host, localhost or an emulator address; with no valid value, Share buttons are hidden and the Android link filter points at the never-resolving `share.invalid`. The Gradle build reads the same dart-define for the App Links host.

Incoming links go through `DeepLinkService` (`lib/services/deep_link_service.dart`): only `/book/<id>` on the configured host is accepted; the link waits until startup has reached Home (not during splash, on login, or over a sheet/dialog) and then pushes Book Details once with `BookDetailsArgs`. Book Details runs the normal sign-in / buy / read flow.

### Android App Links (in the repo)

`MainActivity` has a verified `https` intent filter for `<host>/book/` and a `maanthirigam/deep_links` channel (launch link, links while running, Play Install Referrer). Outside the repo, host this at `https://<domain>/.well-known/assetlinks.json`:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.maanthirigam.maanthirigam",
    "sha256_cert_fingerprints": ["<release signing SHA-256>", "<Play App Signing SHA-256>"]
  }
}]
```

### Deferred links (app not installed)

The web page at `https://<domain>/book/<id>` (outside the repo) should show the book and send phones without the app to:

```text
https://play.google.com/store/apps/details?id=com.maanthirigam.maanthirigam&referrer=book_id%3D<bookId>
```

On first launch the app reads the Play Install Referrer once, validates `book_id`, stores it as pending, opens that Book Details after startup, then clears it. Later launches never re-route. iOS has no install referrer; deferred links on iOS would need a third-party link provider.

### iOS Universal Links (not yet enabled)

The iOS project is unchanged. To enable:

1. Apple Developer → Identifiers → the app ID → enable Associated Domains.
2. Add `ios/Runner/Runner.entitlements` with `com.apple.developer.associated-domains` = `applinks:<domain>` and set it as the Runner target's Code Signing Entitlements.
3. Host `https://<domain>/.well-known/apple-app-site-association` (JSON, no redirect):

   ```json
   {"applinks": {"details": [{"appIDs": ["<TEAMID>.<bundle id>"], "components": [{"/": "/book/*"}]}]}}
   ```

4. Forward the URL to Dart: in `SceneDelegate`, handle `scene(_:willConnectTo:options:)` (`connectionOptions.userActivities`) and `scene(_:continue:)` for `NSUserActivityTypeBrowsingWeb`, and expose them on a `maanthirigam/deep_links` `FlutterMethodChannel` with the same `getInitialLink` / `onLink` methods Android uses. `DeepLinkService` needs no change.

## Remote config

Branding colors, hero, featured refs, catalogue filters, guest free-reading, announcements, and store update prompts come from app-config. Continue-reading is not shown because progress APIs are not implemented.

## Not implemented (contract)

Backend refresh-token endpoint, mobile logout, `/me`, progress APIs, bookmark APIs, paid preview, offline reading, PDF/DOCX, admin APIs.

## Run / test

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define=GOOGLE_SERVER_CLIENT_ID=...
```

Default API is already `https://mandhirigam-admin.onrender.com/api/v1` when no `API_BASE_URL` override is passed.
