import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../profile/user_profile_screen.dart';

/// Search for people, then open their profile (follow / message / report / block).
class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});

  @override
  ConsumerState<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends ConsumerState<PeopleScreen> {
  List<Map<String, dynamic>> _users = [];

  Future<void> _search(String q) async {
    try {
      final res = await ref.read(apiProvider).dio.get('/users/search', queryParameters: {'q': q});
      if (mounted) setState(() => _users = List<Map<String, dynamic>>.from(res.data['users']));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.chat)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.searchPeople),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? Center(child: Text(l.noData))
              : ListView(children: [
                  for (final u in _users)
                    ListTile(
                      leading: CircleAvatar(child: Text((u['displayName'] as String).characters.first.toUpperCase())),
                      title: Text(u['displayName']),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: u['id'])),
                      ),
                    ),
                ]),
        ),
      ]),
    );
  }
}
