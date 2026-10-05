import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/locale_provider.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import '../legal/legal_screens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteAccount),
        content: Text(l.deleteAccountConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      navigator.popUntil((r) => r.isFirst);
    } catch (_) {
      if (context.mounted) showError(context);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final locale = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l.language),
          subtitle: Text(locale.languageCode == 'en' ? 'English' : 'नेपाली'),
          onTap: () => ref.read(localeProvider.notifier).toggle(),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l.terms),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l.privacy),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l.logout),
          onTap: () async {
            final nav = Navigator.of(context);
            await ref.read(authProvider.notifier).logout();
            nav.popUntil((r) => r.isFirst);
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(l.deleteAccount, style: const TextStyle(color: Colors.red)),
          onTap: () => _delete(context, ref),
        ),
      ]),
    );
  }
}
