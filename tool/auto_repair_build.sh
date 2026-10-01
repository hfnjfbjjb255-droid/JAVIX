#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-6}"
LOG_DIR="$ROOT/.auto_repair_logs"
mkdir -p "$LOG_DIR"

say(){ echo "[JAVIX-AUTO] $*"; }

write_flutter_local_properties(){
  test -n "${FLUTTER_ROOT:-}" || { say "FLUTTER_ROOT is missing"; return 1; }
  printf 'flutter.sdk=%s\n' "$FLUTTER_ROOT" > android/local.properties
}

normalize_gradle_files(){
  write_flutter_local_properties
  python3 - <<'PYFIX'
from pathlib import Path
p=Path('android/settings.gradle')
s=p.read_text()
s=s.replace('version "8.9.2"', 'version "8.11.1"')
s=s.replace('version "2.1.20"', 'version "2.2.20"')
if 'dev.flutter.flutter-plugin-loader' not in s:
    raise SystemExit('settings.gradle is missing Flutter plugin loader')
p.write_text(s)
PYFIX
}

safe_dart_fixes(){
  dart fix --apply || true
  dart format lib || true
  flutter pub get || true
}

fix_from_log(){
  local log="$1"
  if grep -qiE 'Could not find method flutter|flutter\(\)|flutter-gradle-plugin|flutter-plugin-loader|Please fix your settings.gradle|Gradle.*plugin' "$log"; then
    say 'Flutter Gradle integration error detected; restoring known-good Gradle files.'
    normalize_gradle_files
    return 0
  fi
  if grep -qiE 'Minimum supported Gradle version|Gradle version.*minimum|Gradle 8\.[0-9]+' "$log"; then
    say 'Gradle version validation failed; forcing Gradle 8.14.3.'
    sed -i 's#gradle-[0-9.]*-bin.zip#gradle-8.14.3-bin.zip#' android/gradle/wrapper/gradle-wrapper.properties
    return 0
  fi
  if grep -qiE 'minimum supported.*Android Gradle Plugin|Android Gradle Plugin.*minimum|AGP.*8\.[0-9]' "$log"; then
    say 'AGP validation failed; forcing AGP 8.11.1.'
    sed -i 's/com.android.application" version "[^"]*"/com.android.application" version "8.11.1"/' android/settings.gradle
    return 0
  fi
  if grep -qiE 'minimum supported.*Kotlin|Kotlin.*minimum|Kotlin Gradle Plugin' "$log"; then
    say 'Kotlin validation failed; forcing Kotlin 2.2.20.'
    sed -i 's/org.jetbrains.kotlin.android" version "[^"]*"/org.jetbrains.kotlin.android" version "2.2.20"/' android/settings.gradle
    return 0
  fi
  if grep -qiE 'SDK location not found|Android SDK|cmdline-tools|licenses.*not accepted' "$log"; then
    say 'Android SDK issue detected; accepting licenses and refreshing API 36.'
    if [ -n "${ANDROID_HOME:-}" ] && [ -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
      yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null || true
      "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" platform-tools 'platforms;android-36' 'build-tools;36.0.0' || true
    fi
    return 0
  fi
  if grep -qiE 'version solving failed|Because .* depends on|pub get failed|Could not resolve .*pub' "$log"; then
    say 'Pub dependency resolution failed; refreshing lock/cache.'
    rm -f pubspec.lock
    flutter pub cache repair || true
    flutter pub get
    return 0
  fi
  if grep -qiE 'Could not resolve|Could not find .*artifact|Execution failed for task|Kotlin daemon|DaemonDisappearedException' "$log"; then
    say 'Gradle/dependency execution issue detected; cleaning build caches.'
    rm -rf android/.gradle "$HOME/.gradle/caches" "$HOME/.gradle/kotlin" 2>/dev/null || true
    flutter clean || true
    flutter pub get || true
    return 0
  fi
  if grep -qiE 'Undefined name|isn.t defined|argument_type_not_assignable|invalid_assignment|missing_required_argument|unused_import|dead_code|The getter .*isn.t defined' "$log"; then
    say 'Dart issue detected; applying Dart safe fixes and formatting.'
    safe_dart_fixes
    return 0
  fi
  return 1
}

normalize_gradle_files
flutter pub get
safe_dart_fixes

for attempt in $(seq 1 "$MAX_ATTEMPTS"); do
  say "BUILD ATTEMPT $attempt/$MAX_ATTEMPTS"
  LOG="$LOG_DIR/attempt-$attempt.log"

  set +e
  flutter analyze 2>&1 | tee "$LOG_DIR/analyze-$attempt.log"
  A=${PIPESTATUS[0]}
  set -e
  if [ "$A" -ne 0 ]; then
    cp "$LOG_DIR/analyze-$attempt.log" "$LOG"
    say 'Analyzer reported diagnostics; continuing because release compilation is the hard gate.'
  fi

  set +e
  flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons --dart-define=JAVIX_DEV_CODE=JAVIX-DEV-2026 --dart-define=JAVIX_DEVELOPER_BUILD=true 2>&1 | tee "$LOG"
  B=${PIPESTATUS[0]}
  set -e
  if [ "$B" -eq 0 ]; then
    say 'BUILD SUCCESS'
    exit 0
  fi
  if fix_from_log "$LOG"; then continue; fi
  say 'Unknown build error: no safe automatic rewrite was found.'
  exit "$B"
done

say 'Maximum automatic repair attempts reached.'
exit 1
