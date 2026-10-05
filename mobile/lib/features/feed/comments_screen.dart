import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui.dart';
import 'feed_repository.dart';

class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _text = TextEditingController();
  late Future<List<Map<String, dynamic>>> _comments = _load();

  Future<List<Map<String, dynamic>>> _load() => ref.read(feedRepositoryProvider).comments(widget.postId);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    try {
      await ref.read(feedRepositoryProvider).addComment(widget.postId, t);
      _text.clear();
      setState(() => _comments = _load());
    } catch (_) {
      if (mounted) showError(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.comments)),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _comments,
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text(l.error));
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) return Center(child: Text(l.noData));
              return ListView(children: [
                for (final c in items)
                  ListTile(title: Text(c['author']['displayName']), subtitle: Text(c['text'])),
              ]);
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _text, decoration: InputDecoration(hintText: l.writeComment))),
              IconButton(onPressed: _send, icon: const Icon(Icons.send), tooltip: l.send),
            ]),
          ),
        ),
      ]),
    );
  }
}
