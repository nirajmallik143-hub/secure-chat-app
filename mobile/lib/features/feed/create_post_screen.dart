import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ui.dart';
import 'feed_repository.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _text = TextEditingController();
  File? _image;
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x != null) setState(() => _image = File(x.path));
  }

  Future<void> _submit() async {
    if (_text.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final repo = ref.read(feedRepositoryProvider);
      final url = _image == null ? null : await repo.uploadImage(_image!);
      await repo.create(_text.text.trim(), imageUrl: url);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showError(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.createPost), actions: [
        TextButton(onPressed: _busy ? null : _submit, child: Text(l.post, style: const TextStyle(color: Colors.white))),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        TextField(controller: _text, maxLines: 6, maxLength: 5000, decoration: InputDecoration(hintText: l.whatsOnYourMind)),
        if (_image != null) Image.file(_image!, height: 200),
        TextButton.icon(onPressed: _pick, icon: const Icon(Icons.photo), label: Text(l.addPhoto)),
        if (_busy) const LinearProgressIndicator(),
      ]),
    );
  }
}
