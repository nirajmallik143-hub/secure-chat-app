import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/ui.dart';

/// AI study helper for students of Nepal. Answers come from the knowledge base
/// that admins train through the backend (/api/tutor/knowledge).
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _text = TextEditingController();
  final _turns = <({bool mine, String text})>[];
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final q = _text.text.trim();
    if (q.length < 2 || _busy) return;
    setState(() {
      _turns.add((mine: true, text: q));
      _busy = true;
    });
    _text.clear();
    try {
      final res = await ref.read(apiProvider).dio.post('/tutor/ask', data: {'question': q});
      if (mounted) setState(() => _turns.add((mine: false, text: res.data['answer'] as String)));
    } catch (_) {
      if (mounted) showError(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.tutor)),
      body: Column(children: [
        Expanded(
          child: _turns.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l.tutorHint, textAlign: TextAlign.center)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _turns.length,
                  itemBuilder: (_, i) {
                    final t = _turns[i];
                    return Align(
                      alignment: t.mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                        decoration: BoxDecoration(
                          color: t.mine ? Theme.of(context).colorScheme.secondary : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: SelectableText(t.text, style: TextStyle(color: t.mine ? Colors.white : Colors.black87)),
                      ),
                    );
                  },
                ),
        ),
        if (_busy) const LinearProgressIndicator(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _text, decoration: InputDecoration(hintText: l.askTutor), onSubmitted: (_) => _ask())),
              IconButton(onPressed: _ask, icon: const Icon(Icons.send), tooltip: l.send),
            ]),
          ),
        ),
      ]),
    );
  }
}
