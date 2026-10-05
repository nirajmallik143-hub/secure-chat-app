import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/ui.dart';
import '../chat/chat_screen.dart';
import '../feed/feed_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  Map<String, dynamic>? _user;
  bool _following = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ref.read(apiProvider).dio.get('/users/${widget.userId}');
      if (mounted) {
        setState(() {
          _user = Map<String, dynamic>.from(res.data['user']);
          _following = res.data['followedByMe'] == true;
        });
      }
    } catch (_) {
      if (mounted) showError(context);
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final res = await ref.read(apiProvider).dio.post('/users/${widget.userId}/follow');
      if (mounted) setState(() => _following = res.data['following'] == true);
    } catch (_) {
      if (mounted) showError(context);
    }
  }

  Future<void> _block() async {
    try {
      await ref.read(apiProvider).dio.post('/users/${widget.userId}/block');
      if (mounted) {
        showMessage(context, AppLocalizations.of(context).blocked);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) showError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final u = _user;
    return Scaffold(
      appBar: AppBar(title: Text(u?['displayName'] ?? l.profile), actions: [
        PopupMenuButton<String>(
          onSelected: (v) => v == 'report' ? showReportDialog(context, ref, userId: widget.userId) : _block(),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'report', child: Text(l.report)),
            PopupMenuItem(value: 'block', child: Text(l.block)),
          ],
        ),
      ]),
      body: u == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(24), children: [
              Center(child: CircleAvatar(radius: 44, child: Text(((u['displayName'] as String).isEmpty ? '?' : (u['displayName'] as String).characters.first).toUpperCase(), style: const TextStyle(fontSize: 32)))),
              const SizedBox(height: 12),
              Center(child: Text(u['displayName'], style: Theme.of(context).textTheme.headlineSmall)),
              Center(child: Text(u['bio'] ?? '')),
              const SizedBox(height: 16),
              FilledButton(onPressed: _toggleFollow, child: Text(_following ? l.unfollow : l.follow)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.chat),
                label: Text(l.chat),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChatScreen(userId: widget.userId, name: u['displayName'])),
                ),
              ),
            ]),
    );
  }
}
