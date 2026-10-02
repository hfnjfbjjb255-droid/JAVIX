# بناء JARVIS - خطوات إنتاج APK (نسخة المستخدم / نسخة المطور)

## المتطلبات
- Flutter SDK 3.19+ (يشمل Dart)
- Android SDK + Android Studio (أو سطر أوامر sdkmanager)
- جهاز أو محاكي بنظام Android 5.0+ (API 21)

## 1) توليد مجلدات المنصة
المشروع لا يحتوي مجلد android/ مسبقاً. نفّذ:

    flutter create . --org com.javix --project-name javix

هذا يولّد android/ و ios/ و test/ دون المساس بـ lib/.

## 2) أذونات أندرويد
عدّل android/app/src/main/AndroidManifest.xml وأضف داخل وسم <manifest>:

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
    <uses-permission android:name="android.permission.VIBRATE"/>

## 3) إعدادات البناء
في android/app/build.gradle تأكد:
- minSdkVersion 21 (أو أعلى) — مطلوب لـ camera و MLKit
- targetSdkVersion 34

## 4) التحقق والبناء

    flutter pub get
    flutter analyze
    flutter build apk --release

الناتج:
    build/app/outputs/flutter-apk/app-release.apk

## 5) الدخول
- نسخة المستخدم: أي اسم مستخدم + اترك حقل رمز المطور فارغاً
- نسخة المطور: أي اسم مستخدم + رمز JAVIX-DEV-2026
  (الرمز معرّف في lib/core/constants.dart -> AppConstants.devAccessCode)

## ملاحظات
- المنطقة الزمنية مثبتة على Asia/Baghdad في lib/main.dart.
  لجعلها تتبع الجهاز تلقائياً: أضف flutter_timezone واستبدل السطر بـ
  tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
- OCR يدعم العربية (TextRecognitionScript.arabic). MLKit يدعم العربية
  كتابةً فقط؛ إذا احتجت أرقاماً/لاتينية أضف recognizer ثانياً بـ latin.
- إشعارات التذكيرات تحتاج SCHEDULE_EXACT_ALARM على أندرويد 12+.
