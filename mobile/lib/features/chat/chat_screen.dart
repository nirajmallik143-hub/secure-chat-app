import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';

/// Real-time one-to-one chat over Socket.IO.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.userId, required this.name});
  final String userId;
  final String name;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _messages = <Map<String, dynamic>>[];
  io.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final api = ref.read(apiProvider);
    try {
      final res = await api.dio.get('/messages/${widget.userId}');
      if (mounted) setState(() => _messages.addAll(List<Map<String, dynamic>>.from(res.data['messages'])));
    } catch (_) {}
    final token = await api.tokens.access;
    final socket = io.io(
      apiUrl,
      io.OptionBuilder().setTransports(['websocket']).setAuth({'token': token}).disableAutoConnect().build(),
    );
    socket.on('message', (data) {
      final m = Map<String, dynamic>.from(data as Map);
      if (m['senderId'] == widget.userId && mounted) setState(() => _messages.add(m));
    });
    socket.connect();
    _socket = socket;
  }

  @override
  void dispose() {
    _socket?.dispose();
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final t = _text.text.trim();
    if (t.isEmpty || _socket == null) return;
    _socket!.emitWithAck('message', {'to': widget.userId, 'text': t}, ack: (res) {
      if (!mounted) return;
      if (res is Map && res['message'] != null) {
        setState(() => _messages.add(Map<String, dynamic>.from(res['message'])));
      } else {
        showError(context);
      }
    });
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final me = ref.watch(authProvider).userId;
    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final mine = m['senderId'] == me;
              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: mine ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(m['text'], style: TextStyle(color: mine ? Colors.white : Colors.black87)),
                ),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(children: [
              Expanded(child: TextField(controller: _text, decoration: InputDecoration(hintText: l.messageHint), onSubmitted: (_) => _send())),
              IconButton(onPressed: _send, icon: const Icon(Icons.send), tooltip: l.send),
            ]),
          ),
        ),
      ]),
    );
  }
}
