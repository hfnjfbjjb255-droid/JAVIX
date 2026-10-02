# JARVIS build/deploy

## 1. Start the backend

```bash
cd backend
cp .env.example .env
# Set JWT_SECRET and OPENAI_API_KEY in .env.
npm install
npm start
```

## 2. Configure the Android build

Set the GitHub repository variable `JARVIS_BACKEND_URL` to your HTTPS backend URL.
The workflow passes it as `--dart-define=JARVIS_BACKEND_URL=...`.

For local Flutter builds:

```bash
flutter pub get
flutter analyze
flutter build apk --release --target-platform android-arm64 \
  --dart-define=JAVIX_DEV_CODE=JAVIX-DEV-2026 \
  --dart-define=JAVIX_DEVELOPER_BUILD=true \
  --dart-define=JARVIS_BACKEND_URL=https://YOUR-DOMAIN
```

## 3. Store products

Create:
- `jarvis_pro_monthly`
- `jarvis_pro_3months`
- `jarvis_pro_yearly`

The app uses Flutter's in-app purchase flow. Server verification must be configured before charging real users.

## 4. OAuth

Configure Google and Apple credentials on the backend and set `APP_URL` to the public backend URL. OAuth callbacks redirect back to `jarvis://auth`.

## 5. Production security

- Never commit `.env`.
- Never put an OpenAI API key in Flutter code or APK.
- Use HTTPS only.
- Replace the development phone OTP logging mode with Twilio credentials.
- Enable store-side receipt verification before enabling paid subscriptions.
