# JAVIX clean build configuration

Prepared for Flutter 3.47.3 with Gradle 8.14.3, Android Gradle Plugin 8.11.1, Kotlin 2.2.20, and Android API 36.

The previous failure at `Prepare Gradle wrapper` was caused by the workflow trying to prepare the wrapper before the Android Gradle configuration was deterministically repaired. This version repairs the Android files first, then creates/validates the wrapper, then runs pub/analyze/build.

The build workflow retries a limited set of known failures automatically. Unknown source-code errors are not blindly rewritten.
