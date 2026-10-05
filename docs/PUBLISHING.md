# Publishing checklist

Application ID / bundle ID: `com.nirajmallik.nepalconnect` (change it before your first upload if you rename the app, it cannot be changed afterwards).

## 0. Before you start
- [ ] Deploy the backend over **HTTPS** (a managed Postgres, S3-compatible bucket, strong `JWT_*` secrets) and note the URL.
- [ ] Build the app with `--dart-define=API_URL=https://your-api`.
- [ ] Host the Privacy Policy and Terms (from `docs/PRIVACY_POLICY.md`, `docs/TERMS.md`) at public URLs, after filling in the placeholders and legal review.
- [ ] Add `assets/images/icon.png` (1024×1024) and `splash.png`, run `dart run flutter_launcher_icons && dart run flutter_native_splash:create`.
- [ ] Set up a moderation contact and process: reports are stored in the `Report` table and must be reviewed (within 24 hours is the commonly expected standard).

## 1. Google Play Console
- [ ] Create a [Play Console developer account](https://play.google.com/console) (one-time US$25 fee; identity verification). New personal accounts must run a **closed test with 12+ testers for 14 days** before production access.
- [ ] Generate an **upload keystore** and keep it backed up and private:
  `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
- [ ] Copy `mobile/android/key.properties.example` to `key.properties` and fill it in (never commit it). Enrol in **Play App Signing** when creating the app.
- [ ] Build: `flutter build appbundle --release`. Increase `version:` in `pubspec.yaml` (`1.0.0+2`) for every upload.
- [ ] Create the app in the console (name, default language, free/paid).
- [ ] **Store listing**: short (80) and full (4000) description, 512×512 icon, 1024×500 feature graphic, ≥2 phone screenshots, category *Social*.
- [ ] **App content**: Privacy Policy URL; **Data Safety form** (declare: personal info [name, email, phone], photos, messages, user content, app activity; data encrypted in transit; users can request deletion; provide the account-deletion URL/in-app path); **Content rating** questionnaire (UGC / user interaction → expect Teen or higher); target audience (13+); ads declaration; Government/news/health declarations as applicable.
- [ ] **User-generated content policy**: in-app reporting and blocking are implemented. Describe moderation in the listing/review notes.
- [ ] **Account deletion**: in-app (Settings → Delete my account) and a web URL where users can request deletion (required field in Data Safety).
- [ ] Upload the AAB to *Internal testing* → *Closed testing* → *Production*, add release notes, submit for review.
- [ ] Optional automation: create a Play service account JSON, store it as `PLAY_STORE_JSON_KEY`, run the **Mobile Android (AAB)** workflow with `upload_to_play`.

## 2. Apple App Store Connect
- [ ] Enrol in the [Apple Developer Program](https://developer.apple.com/programs/) (US$99/year).
- [ ] Register the App ID `com.nirajmallik.nepalconnect` and enable *Push Notifications* if used.
- [ ] Create an **Apple Distribution certificate** (export as `.p12`) and an **App Store provisioning profile** for the App ID. Fill `mobile/ios/ExportOptions.plist` (team ID and profile name).
- [ ] Create the app in **App Store Connect** (name, bundle ID, SKU, primary language).
- [ ] Build on macOS: `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`, upload with Xcode Organizer, *Transporter*, or fastlane (`bundle exec fastlane beta`).
- [ ] **TestFlight**: wait for build processing, answer export compliance (the app sets `ITSAppUsesNonExemptEncryption=false`; it only uses standard HTTPS), add internal and external testers.
- [ ] **App Privacy** ("nutrition labels"): contact info, user content, identifiers, usage data; state that data is linked to the user and not used for tracking.
- [ ] Listing: description, keywords, support URL, privacy policy URL, screenshots (6.7" and 6.5" iPhone required), age rating.
- [ ] **Review guidelines for UGC (Guideline 1.2)**. The app must have: a way to filter objectionable content, a mechanism to **report** content, the ability to **block** abusive users, and published contact info; developers must act on reports within 24 hours. Describe these in *App Review notes*.
- [ ] **Guideline 5.1.1(v)**: apps with account creation must offer **in-app account deletion**: implemented (Settings → Delete my account).
- [ ] Provide a **demo account** in review notes. Submit for review.

## 3. GitHub secrets used by CI

| Secret | Used by | Description |
| --- | --- | --- |
| `API_URL` | both mobile workflows | Production API base URL |
| `ANDROID_KEYSTORE_BASE64` | android | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS` | android | Keystore details |
| `PLAY_STORE_JSON_KEY` | android (optional) | Play service account JSON |
| `IOS_CERTIFICATE_BASE64`, `IOS_CERTIFICATE_PASSWORD` | ios | Distribution certificate `.p12` |
| `IOS_PROVISIONING_PROFILE_BASE64`, `IOS_PROVISIONING_PROFILE_NAME` | ios | App Store provisioning profile |
| `APPLE_TEAM_ID` | ios | Team ID |
| `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_CONTENT` | ios (optional TestFlight) | App Store Connect API key |

Never commit keystores, `.p12`/`.p8` files, provisioning profiles, or `.env` files; `.gitignore` excludes them.
