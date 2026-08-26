# Maanthirigam

Flutter mobile application — **UI foundation only** (screens and backend integrations come later).

## Architecture

```text
lib/
  app/                 # App root, bootstrap
  core/                # Non-UI shared constants/utils/extensions
  design_system/       # Theme tokens + reusable UI components
  routing/             # Centralized routes & navigator
  features/            # Feature modules (screens + feature widgets)
  shared/              # Cross-feature non-primitive widgets
assets/
  images/ icons/ fonts/
```

**Rule:** If a UI pattern appears more than once (or is likely to), implement it as a reusable component under `design_system/` instead of duplicating it.

## Screen workflow

Screenshot/Design → UI analysis → reusable components → screen implementation.

## Verify

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```
