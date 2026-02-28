## Quick context for AI coding agents

This repository is a Flutter mobile app (CRMMobile). Key facts an agent needs immediately:

- Flutter project root: `pubspec.yaml`, `android/`, `ios/`, `lib/`.
- Uses Firebase (see `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`).
- Code generation is used (files like `main.reflectable.dart` and build stamps in `build/`). Run build_runner for generation when necessary.

## High-level architecture

- UI layer: `lib/ui/` (widgets, buttons, screens). Example: `lib/ui/buttons/default_button.dart` — uses shared style helpers from `lib/helpers/ui_helper.dart`.
- State & business logic: `lib/blocks/` (Cubit/BLoC patterns; e.g. `list_cubit.dart`).
- API layer: `lib/api/` (network clients and endpoints; `auth_api.dart`, `base_api.dart`).
- Persistence & DB: `lib/db/` (local storage and models).
- Services & repository: `lib/services/`, `lib/repository/` (feature boundaries and orchestration).

Why this matters: changes to UI often need matching updates in `blocks`/`services` and occasionally `api` (data contracts). Keep cross-layer impacts in mind.

## Useful developer workflows & commands

- Install deps: `flutter pub get`
- Run app (device/emulator): `flutter run -d <device>`
- Run codegen: `flutter pub run build_runner build --delete-conflicting-outputs`
- Analyze: `flutter analyze`
- Format: `dart format .` (or `flutter format .`)
- Tests: `flutter test` (unit tests live under `test/`)
- iOS pods: when working with iOS, run `cd ios && pod install` if you change native deps.

Notes: key signing and secrets live in `android/key.properties` and `ios` signing settings — do not commit private keys.

## Project-specific conventions & patterns

- Styling/helpers: UI styles and color constants live in `lib/helpers/ui_helper.dart`. Prefer these helpers (`textStyle`, color constants like `ColorOrange`) rather than ad-hoc values. Example: `lib/ui/buttons/default_button.dart` reads color constants and uses `textStyle(... )`.
- Buttons & loading: components often expose `loading` and `enable` booleans to control state (see `DefaultButton` pattern).
- APIs: `lib/api/base_api.dart` defines common request handling; individual endpoints extend it. Follow existing request/response shapes.
- State management: `blocks/` uses Cubit-like naming (`*_cubit.dart`). Keep cubit methods small and side-effect-free; call services/repository for I/O.
- Generated files: `lib/main.reflectable.dart` and `lib/generated_plugin_registrant.dart` are generated — do not edit manually.

## Integration points & external deps

- Firebase (auth, analytics): `lib/firebase_options.dart` and platform JSON/Plist files.
- Native plugins: Android and iOS plugin registrants are used; when adding plugins, ensure they are added to `pubspec.yaml` and native manifests.
- CI hints: `build.yaml` and `devtools_options.yaml` exist — CI may use them for builds or codegen.

## How to make safe edits

1. Run `flutter pub get`.
2. Make small, focused changes and run `flutter analyze` and `flutter test`.
3. If you change public APIs (models or API contracts), update callers in `lib/blocks`, `lib/services`, and tests.
4. For UI changes, prefer using helpers in `lib/helpers/ui_helper.dart` for consistency.

## Quick examples (where to look)

- Changing button visuals: `lib/ui/buttons/default_button.dart` (uses `ui_helper.dart` constants and `loading` pattern).
- Auth or network changes: `lib/api/auth_api.dart` and `lib/api/base_api.dart`.
- Add feature state: `lib/blocks/` (create a new cubit and reference in the UI).

## Safety & secrets

- Do not commit `key.properties` contents or any private keys. If you must test with real credentials, use environment variables or local-only config.

---
If anything above is unclear or you want me to expand an area (codegen details, CI steps, or examples), tell me which part and I'll iterate.
