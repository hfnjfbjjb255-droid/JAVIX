# JAVIX Gradle build fix

The recurring `Could not find method flutter() ... on project ':app'` error happened while GitHub/Gradle was configuring the Android app to create the Gradle wrapper.

This version contains three safeguards:

1. `android/app/build.gradle` has a compatibility guard around the Flutter extension. It only prevents the wrapper-generation phase from crashing; the real Flutter Gradle plugin still supplies the extension for the actual Flutter build.
2. `android/settings.gradle` can locate Flutter from either `android/local.properties` or the CI `FLUTTER_ROOT` environment variable.
3. The unnecessary `evaluationDependsOn(":app")` was removed from `android/build.gradle`, so root Gradle tasks do not force extra app evaluation.

The GitHub workflow is also included in `.github/workflows/build-apk.yml`.
