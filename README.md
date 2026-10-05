# Nepal Connect 🇳🇵

> *"Nepal's own social platform."* A Facebook-style social network built for people in Nepal: share posts and photos, follow friends, chat in real time, and learn with an AI study helper, in **English and नेपाली**.

"Nepal Connect" is a placeholder name (see [mobile/README.md](mobile/README.md) for how to rename it). The project was started as `secure-chat-app` with the goal of a fully secure, end-to-end encrypted messenger; that goal is kept on the [roadmap](#roadmap).

## Features

- Sign up / log in with **email or phone**, JWT access + rotating refresh tokens
- News feed with text and image posts, likes and comments
- User profiles (edit), follow / unfollow
- **Real-time chat** (Socket.IO) and notifications
- **AI study helper for students of Nepal**: a tutor you can *train* with your own notes, syllabus and Q&A (see [AI tutor](#ai-study-helper-training))
- Language toggle English / नेपाली (Flutter `l10n`)
- Store-compliance features: Terms of Service, Privacy Policy, **report & block** users/content, **account deletion**
- Nepal-inspired theme (crimson and blue)

## Architecture

```
┌──────────────────────┐   HTTPS REST    ┌───────────────────────────┐      ┌──────────────┐
│ Flutter app          │ ──────────────► │ Node.js + Express (TS)    │ ───► │ PostgreSQL   │
│ Android + iOS        │                 │  auth · posts · users     │      │ (Prisma)     │
│ Riverpod · l10n      │ ◄────────────── │  tutor · reports · notifs │      └──────────────┘
│                      │   Socket.IO     │  Socket.IO (chat, notifs) │ ───► ┌──────────────┐
└──────────────────────┘   (WebSocket)   └──────────┬────────────────┘      │ S3-compatible│
                                                    │ optional              │ image storage│
                                                    ▼                       └──────────────┘
                                         OpenAI-compatible LLM (AI tutor)
```

## Tech stack

| Area | Tech |
| --- | --- |
| Mobile | Flutter 3.24, Riverpod, Dio, Socket.IO client, `flutter_localizations` |
| Backend | Node.js 20, TypeScript, Express, Socket.IO, Prisma, zod, helmet, express-rate-limit |
| Data | PostgreSQL, S3-compatible object storage (AWS S3, MinIO, R2, Spaces) |
| Auth | bcrypt, JWT access tokens, rotating hashed refresh tokens |
| CI/CD | GitHub Actions, fastlane (`supply`, `pilot`, `deliver`) |

## Repository layout

```
backend/   Express + Prisma API, Socket.IO, Jest tests, Dockerfile, docker-compose.yml
mobile/    Flutter app (Android + iOS), release config, fastlane
docs/      PUBLISHING.md, PRIVACY_POLICY.md, TERMS.md
.github/   CI workflows
```

## Setup and run

### Backend

```bash
cd backend
cp .env.example .env              # set secrets (JWT_ACCESS_SECRET must be at least 32 chars)
docker compose up --build         # API on :4000 + PostgreSQL (migrations run on start)
```

Without Docker (needs a local PostgreSQL):

```bash
npm install
npx prisma migrate deploy
npm run dev
npm test                          # Jest tests (auth, posts, tutor)
```

Health check: `GET http://localhost:4000/health`.

### Mobile

```bash
cd mobile
flutter create --platforms=android,ios --org com.nirajmallik --project-name nepalconnect .   # one-time, never overwrites existing files
flutter pub get
dart run flutter_launcher_icons && dart run flutter_native_splash:create   # after adding assets/images/icon.png and splash.png
flutter run --dart-define=API_URL=http://10.0.2.2:4000      # Android emulator -> host machine
```

Use `http://localhost:4000` for the iOS simulator, or your computer's LAN IP for a real device.

## AI study helper (training)

The tutor answers student questions in English or Nepali. It retrieves the best-matching entries from a knowledge base **you train**, then (optionally) asks an LLM to answer using them.

1. Set `ADMIN_EMAILS` in `backend/.env` to the account(s) allowed to train it.
2. Optional: set `AI_API_KEY` (and `AI_BASE_URL`, `AI_MODEL`) for any OpenAI-compatible API. Without a key the helper returns the matching notes directly.
3. Add training content (notes, syllabus, solved questions), authenticated as an admin:

```bash
curl -X POST http://localhost:4000/api/tutor/knowledge \
  -H "Authorization: Bearer <your access token>" -H "Content-Type: application/json" \
  -d '{"title":"नेपालको राजधानी","content":"काठमाडौँ नेपालको राजधानी हो।","subject":"Social Studies","grade":"SEE","language":"ne"}'
```

`GET /api/tutor/knowledge` lists entries and `DELETE /api/tutor/knowledge/:id` removes one. Students use the **Study Helper** tab in the app (`POST /api/tutor/ask`, rate limited). Tune the tutor's behaviour with `AI_SYSTEM_PROMPT`.

## Build for release

```bash
cd mobile
# Android: copy android/key.properties.example -> android/key.properties and fill in your keystore details
flutter build apk --release --dart-define=API_URL=https://api.yourdomain.com          # APK for direct install
flutter build appbundle --release --dart-define=API_URL=https://api.yourdomain.com    # AAB for Google Play
# iOS (macOS + Xcode, edit ios/ExportOptions.plist first)
flutter build ipa --release --dart-define=API_URL=https://api.yourdomain.com --export-options-plist=ios/ExportOptions.plist
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk`, `build/app/outputs/bundle/release/app-release.aab`, `build/ios/ipa/*.ipa`.
GitHub Actions can build the signed AAB and IPA for you; see the workflows in `.github/workflows` and [docs/PUBLISHING.md](docs/PUBLISHING.md) for the required secrets.

## Install on a device

- **Android**: enable *USB debugging*, then `flutter install`, or `adb install build/app/outputs/flutter-apk/app-release.apk`, or send the APK to the phone and open it (allow "Install unknown apps").
- **iOS**: open `ios/Runner.xcworkspace` in Xcode, select your device and Run (free Apple ID works for 7-day builds), or distribute through **TestFlight**.

## Publishing

Follow [docs/PUBLISHING.md](docs/PUBLISHING.md) for the full Google Play and App Store checklists, including the Data Safety form, App Privacy, and UGC moderation requirements. Templates: [Privacy Policy](docs/PRIVACY_POLICY.md), [Terms](docs/TERMS.md).

## Roadmap

- 🔐 **End-to-end encrypted messaging** (the original goal of this repo), e.g. Signal-protocol style key exchange so the server cannot read chats
- Push notifications (FCM / APNs), email/SMS (OTP) verification
- Admin moderation dashboard for reports
- Groups, stories, video
- Smarter tutor: embeddings-based retrieval and curriculum packs for SEE / +2

## Contributing & security

See [CONTRIBUTING.md](CONTRIBUTING.md) and [SECURITY.md](SECURITY.md).

## License

[MIT](LICENSE) © 2026 Niraj Mallik
