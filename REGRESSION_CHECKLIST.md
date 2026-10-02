# JARVIS regression checklist

This file records the failures that previously broke builds and the protections kept in this update.

- GoldCard imports are present where the widgets are used.
- `user_home_screen.dart` has balanced widget parentheses.
- `ai_gateway_screen.dart` was kept syntactically clean after the previous malformed-parenthesis failures.
- `dev_dashboard_screen.dart` keeps the `AppPermission` dependency available.
- `reminder_service.dart` keeps `uiLocalNotificationDateInterpretation` for absolute notification times.
- Flutter Gradle plugin loader/app plugin configuration remains in place.
- Gradle wrapper is normalized to 8.14.3 by the workflow/repair script.
- Android compile/build tooling is pinned by the existing CI workflow.
- The release workflow verifies that an APK exists and is non-empty before upload.
- JARVIS developer access remains build-time gated.
- AI secrets are server-side only when `JARVIS_BACKEND_URL` is configured.
- Free media limits are enforced on the server: 7 images/day and 3 videos/day.
