import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class _LegalPage extends StatelessWidget {
  const _LegalPage({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Text(body)),
      );
}

// Keep in sync with docs/TERMS.md and docs/PRIVACY_POLICY.md. Have a lawyer review before publishing.
const termsText = '''
Terms of Service (summary)

By using this app you agree to:
1. Be at least 13 years old and provide accurate information.
2. Not post illegal, hateful, harassing, sexually explicit, violent or misleading content.
3. Respect other users. We have zero tolerance for objectionable content or abusive users.
4. Accept that content may be reported by other users, reviewed and removed within 24 hours, and that violating accounts may be suspended or deleted.
5. Use the AI study helper as a learning aid only; answers may be wrong.

You can report content, block users, and delete your account at any time from the app.
''';

const privacyText = '''
Privacy Policy (summary)

We collect: your name, email or phone number, profile information, posts, comments, messages, photos you choose to upload, and basic technical data needed to run the service.

We use it to provide the app, keep it safe, and show you notifications. We do not sell your personal data.

You can edit your profile, and permanently delete your account and associated data from Settings > Delete my account.

Contact: see the project repository for the support address.
''';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) => _LegalPage(title: AppLocalizations.of(context).terms, body: termsText);
}

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) => _LegalPage(title: AppLocalizations.of(context).privacy, body: privacyText);
}
