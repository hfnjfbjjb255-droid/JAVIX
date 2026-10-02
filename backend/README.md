# JARVIS Backend

This backend is the security boundary for JARVIS. The Android app must never contain an OpenAI secret.

## Provides
- Email/password registration and login with bcrypt + JWT.
- Phone OTP with Twilio in production (development mode logs OTP to the server console).
- Server-side 7 images/day and 3 videos/day limits for free users.
- Pro entitlement hook for monthly / 3-month / yearly store products.
- OpenAI Responses API proxy for chat.
- OpenAI image generation proxy.
- Configurable video provider proxy; set `AI_VIDEO_URL` and `AI_VIDEO_MODEL` to the provider/model enabled for your account.
- Rate limiting and server-side authorization.

## Run

```bash
cd backend
cp .env.example .env
# Set JWT_SECRET and OPENAI_API_KEY; never commit .env.
npm install
npm start
```

Then build the app with:

```bash
flutter build apk --release --dart-define=JARVIS_BACKEND_URL=https://YOUR-DOMAIN
```

## Production billing

Create these store products exactly:
- `jarvis_pro_monthly`
- `jarvis_pro_3months`
- `jarvis_pro_yearly`

Before accepting real money, implement and enable Google Play Developer API / App Store Server API verification in `/billing/verify`. The current endpoint deliberately returns 501 rather than trusting a client-supplied purchase token.

## OAuth

Google and Apple buttons open the backend OAuth start endpoints. The current backend returns an explicit configuration response until provider credentials and a verified callback flow are configured. Do not accept unverified identity claims from the client.
