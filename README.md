# Maanthirigam

Flutter mobile app for Mantirigam, integrated with the backend contract in
`Docs/MOBILE_APP_INTEGRATION.md`.

## API base URL

Default:

```text
https://api.maandhrigam.demosvr.in/api/v1
```

Startup request:

```text
GET https://api.maandhrigam.demosvr.in/api/v1/app-config
```

## Run

```bash
flutter pub get
flutter run
```

Optional: copy `dart_defines.example.json` → `dart_defines.json` and launch with:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Local Android emulator against a PC backend:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5050/api/v1
```
