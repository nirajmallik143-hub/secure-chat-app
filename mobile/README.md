# Nepal Connect mobile app (Flutter)

Single codebase for Android and iOS. Package / bundle ID: `com.nirajmallik.nepalconnect`.

## First-time setup

The repo contains the Dart source, localization, Android release config and iOS Info.plist/ExportOptions.
Generate the remaining platform scaffolding (Gradle wrapper jar, Xcode project, ...) once. It never overwrites existing files:

```bash
cd mobile
flutter create --platforms=android,ios --org com.nirajmallik --project-name nepalconnect .
flutter pub get
dart run flutter_launcher_icons && dart run flutter_native_splash:create   # after adding assets/images/icon.png & splash.png (1024x1024 PNG)
flutter run --dart-define=API_URL=http://10.0.2.2:4000
```

## Rename the app
- Display name: `android/app/src/main/AndroidManifest.xml` (`android:label`), `ios/Runner/Info.plist` (`CFBundleDisplayName`), `lib/l10n/*.arb` (`appName`).
- Package ID: `android/app/build.gradle`, `ios` bundle identifier in Xcode, Fastlane `Appfile`s, `ios/ExportOptions.plist`.
