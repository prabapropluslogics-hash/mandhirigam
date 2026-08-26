# Feature modules

Each product area lives under `lib/features/<feature_name>/`.

Recommended layout per feature (expand as needed):

```text
features/
  <feature_name>/
    presentation/
      screens/          # full pages / routes for this feature
      widgets/          # feature-specific reusable widgets only
    # Later (when business logic arrives):
    # domain/
    # data/
```

Rules:

1. Do **not** put reusable cross-app UI here — that belongs in `design_system/`.
2. If a widget is used by 2+ features, move it to `design_system/` or `shared/widgets/`.
3. Screens must compose design-system components; avoid hardcoding colors/spacing.
4. Feature folders are created when the first screen for that feature is implemented.
