# Repository Guidelines

## Project Structure

- `lib/`: Main Flutter source (GetX).
  - `lib/views/`: UI pages/widgets (e.g. `lib/views/home/`, `lib/views/overview/`)
  - `lib/controller/`: GetX controllers
  - `lib/service/`: Long-lived services (WebSocket, scripts, theme, locale)
  - `lib/model/`: Data models and enums
  - `lib/widgets/` / `lib/component/`: Reusable UI components
  - `lib/translation/`: i18n strings and localization wiring
- `assets/`: App assets (icons, release notes)
- `test/`: Flutter unit/widget tests (`flutter_test`)
- `script/`: Release/maintenance scripts (Python)
- Platform folders: `windows/`, `macos/`, `linux/`, `android/`, `ios/`, `web/`

## Build, Test, and Development Commands

Recommended toolchain: Flutter `3.27.1` / Dart `3.6.0` (see `README.md`).

- `flutter pub get`: Install dependencies
- `flutter run -d windows` (or `macos`/`linux`/`chrome`): Run locally
- `flutter test`: Run all tests (or `flutter test test/<file>_test.dart`)
- `flutter analyze`: Static analysis (lints from `analysis_options.yaml`)
- `dart format .`: Format Dart code (prefer formatting before PRs)
- Windows packaging (if needed): `dart run msix:create` (see `pubspec.yaml` `msix_config`)

## Coding Style & Naming

- Follow `flutter_lints` (`analysis_options.yaml`); keep analyzer warnings at zero.
- Dart formatting: 2-space indentation; use `dart format`.
- Filenames: `snake_case.dart`; types: `PascalCase`; members: `lowerCamelCase`.
- Prefer small, focused widgets; keep state in GetX controllers/services.
- Write code in styled_widget style and reduce code nesting levels.

## Testing Guidelines

- Framework: `flutter_test`.
- Add/adjust tests when changing business logic in `lib/service/` or controllers.
- Name tests `*_test.dart`; group by feature (e.g. `test/service/...`).

## Commit & Pull Request Guidelines

- Commit messages commonly use Conventional-Commit style (e.g. `feat: ...`, `fix(scope): ...`); keep them imperative and scoped.
- PRs should include: summary, screenshots for UI changes, and reproduction/verification steps.
- Do not edit generated Flutter files (e.g. `windows/flutter/generated_*`, `macos/Flutter/GeneratedPluginRegistrant.swift`); regenerate via Flutter tooling if needed.

## Configuration & Safety Tips

- The app expects a running backend (OAS) reachable via configured address; avoid hardcoding endpoints.
- Secrets/credentials should not be committed; use local settings/storage instead.
- Answer and think in Chinese before writing code.
- All places in the code that use text must be internationalized and translated into Chinese and English .
- Use the I18n constant to replace all Chinese in the code, while placing the Chinese and English translations under the 'translation/' directory

