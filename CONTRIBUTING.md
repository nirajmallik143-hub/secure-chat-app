# Contributing

Thanks for helping build Nepal Connect!

1. Fork the repo and create a branch: `git checkout -b feature/my-change`.
2. **Backend** (`/backend`): `npm install`, then `npm run lint`, `npm test` and `npm run build` must pass.
3. **Mobile** (`/mobile`): `flutter pub get`, `flutter analyze` and `flutter test` must pass. Add new strings to **both** `lib/l10n/app_en.arb` and `app_ne.arb`.
4. Keep PRs focused, add tests for new behaviour, and describe what and why.
5. Never commit secrets, keystores, certificates or `.env` files.

By contributing you agree your work is licensed under the [MIT License](LICENSE).
