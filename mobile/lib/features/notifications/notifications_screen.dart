import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

final notificationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(apiProvider).dio;
  final res = await dio.get('/notifications');
  await dio.post('/notifications/read');
  return List<Map<String, dynamic>>.from(res.data['notifications']);
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  String _text(Map<String, dynamic> n) {
    final who = n['actor']?['displayName'] ?? '';
    switch (n['type']) {
      case 'like':
        return '$who ❤';
      case 'comment':
        return '$who 💬';
      case 'follow':
        return '$who +';
      default:
        return who;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.notifications)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: items.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(l.error))]),
          data: (list) => list.isEmpty
              ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(l.noData)))])
              : ListView(children: [
                  for (final n in list)
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(_text(n)),
                      subtitle: Text(n['type']),
                    ),
                ]),
        ),
      ),
    );
  }
}
