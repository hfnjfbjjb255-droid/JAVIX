# JARVIS rebuilt source package

This package rebuilds the affected areas without changing the existing feature set.

## Included fixes
- Rebuilt `login_screen.dart` from scratch:
  - username-only local account
  - no Google / Apple / phone / email UI
  - no backend call from login
  - single background image
  - no duplicate JARVIS logo overlay
  - responsive SafeArea/scroll layout
- Rebuilt local `PermissionService` flow:
  - local username registration/login
  - local session restore
  - no backend authentication in temporary local mode
- Added `LanguageService` with 20 major world languages.
- Added a Languages selector to login, Home, and Profile.
- Added a Translation screen with source/target language selection and Google Translate handoff.
- Improved native Android location handling:
  - recognizes either precise or approximate location permission
  - uses cached location immediately when available
  - avoids duplicate MethodChannel result callbacks
- Improved location status messaging.
- Home screen no longer polls the backend every 20 seconds in local mode.

## Important
The language selector provides the locale infrastructure and language selection UI. Existing screens that contain hard-coded Arabic labels still need individual string migration for full translated UI coverage; this package does not falsely claim those hard-coded strings are automatically translated.

No APK, `.env`, `.git`, `build`, `.dart_tool`, or `node_modules` is included.
