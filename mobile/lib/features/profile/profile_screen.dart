import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final user = ref.watch(authProvider).user ?? {};
    final name = (user['displayName'] ?? '') as String;
    return Scaffold(
      appBar: AppBar(title: Text(l.profile), actions: [
        IconButton(
          tooltip: l.settings,
          icon: const Icon(Icons.settings),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
      ]),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Center(child: CircleAvatar(radius: 44, child: Text(name.isEmpty ? '?' : name.characters.first.toUpperCase(), style: const TextStyle(fontSize: 32)))),
        const SizedBox(height: 12),
        Center(child: Text(name, style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 8),
        Center(child: Text((user['bio'] ?? '') as String)),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: Text(l.editProfile),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
        ),
      ]),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _name = TextEditingController(text: ref.read(authProvider).user?['displayName'] ?? '');
  late final _bio = TextEditingController(text: ref.read(authProvider).user?['bio'] ?? '');

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      final res = await ref.read(apiProvider).dio.patch('/users/me', data: {
        'displayName': _name.text.trim(),
        'bio': _bio.text.trim(),
      });
      ref.read(authProvider.notifier).updateUser(Map<String, dynamic>.from(res.data['user']));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) showError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.editProfile)),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        TextField(controller: _name, decoration: InputDecoration(labelText: l.displayName)),
        const SizedBox(height: 16),
        TextField(controller: _bio, maxLines: 3, maxLength: 300, decoration: InputDecoration(labelText: l.bio)),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ]),
    );
  }
}
