import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/locale_provider.dart';
import '../../core/ui.dart';
import '../legal/legal_screens.dart';
import 'auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _id = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _signup = false;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = ref.read(authProvider.notifier);
    final ok = _signup
        ? await auth.signup(_id.text, _password.text, _name.text.trim())
        : await auth.login(_id.text, _password.text);
    if (!ok && mounted) showError(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loading = ref.watch(authProvider).loading;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.appName),
        actions: [
          TextButton(
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            child: const Text('EN / ने', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        if (_signup) ...[
          TextField(controller: _name, decoration: InputDecoration(labelText: l.displayName)),
          const SizedBox(height: 16),
        ],
        TextField(
          controller: _id,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(labelText: l.emailOrPhone),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(labelText: l.password),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: loading ? null : _submit,
          child: loading
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(_signup ? l.signup : l.login),
        ),
        TextButton(
          onPressed: () => setState(() => _signup = !_signup),
          child: Text(_signup ? l.haveAccount : l.noAccount),
        ),
        const SizedBox(height: 16),
        Text(l.agreeTerms, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
            child: Text(l.terms),
          ),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
            child: Text(l.privacy),
          ),
        ]),
      ]),
    );
  }
}
