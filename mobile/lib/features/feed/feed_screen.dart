import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui.dart';
import '../auth/auth_controller.dart';
import 'comments_screen.dart';
import 'create_post_screen.dart';
import 'feed_repository.dart';

Future<void> showReportDialog(BuildContext context, WidgetRef ref, {String? postId, String? userId}) async {
  final l = AppLocalizations.of(context);
  final controller = TextEditingController();
  final reason = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.report),
      content: TextField(controller: controller, decoration: InputDecoration(hintText: l.reportReason), maxLength: 500),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l.report)),
      ],
    ),
  );
  if (reason == null || reason.length < 3 || !context.mounted) return;
  try {
    await ref.read(feedRepositoryProvider).report(postId: postId, userId: userId, reason: reason);
    if (context.mounted) showMessage(context, l.reportSent);
  } catch (e) {
    if (context.mounted) showError(context);
  }
}

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final feed = ref.watch(feedProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.appName)),
      floatingActionButton: FloatingActionButton(
        tooltip: l.createPost,
        onPressed: () async {
          final created = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
          if (created == true) ref.invalidate(feedProvider);
        },
        child: const Icon(Icons.edit),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feedProvider),
        child: feed.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Text(l.error))]),
          data: (posts) => posts.isEmpty
              ? ListView(children: [Padding(padding: const EdgeInsets.all(24), child: Center(child: Text(l.noData)))])
              : ListView.builder(itemCount: posts.length, itemBuilder: (_, i) => PostCard(post: posts[i])),
        ),
      ),
    );
  }
}

class PostCard extends ConsumerStatefulWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  late bool _liked = widget.post.likedByMe;
  late int _likes = widget.post.likes;

  Future<void> _like() async {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    try {
      await ref.read(feedRepositoryProvider).toggleLike(widget.post.id);
    } catch (_) {
      if (mounted) {
        setState(() {
          _liked = !_liked;
          _likes += _liked ? 1 : -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final post = widget.post;
    final me = ref.watch(authProvider).userId;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(child: Text(post.authorName.characters.first.toUpperCase())),
            const SizedBox(width: 8),
            Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (post.authorId != me)
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'report') {
                    await showReportDialog(context, ref, postId: post.id);
                  } else {
                    try {
                      await ref.read(feedRepositoryProvider).block(post.authorId);
                      ref.invalidate(feedProvider);
                      if (context.mounted) showMessage(context, l.blocked);
                    } catch (_) {
                      if (context.mounted) showError(context);
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'report', child: Text(l.report)),
                  PopupMenuItem(value: 'block', child: Text(l.block)),
                ],
              ),
          ]),
          const SizedBox(height: 8),
          Text(post.text),
          if (post.imageUrl != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover, width: double.infinity),
            ),
          ],
          Row(children: [
            TextButton.icon(
              onPressed: _like,
              icon: Icon(_liked ? Icons.favorite : Icons.favorite_border),
              label: Text('$_likes'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => CommentsScreen(postId: post.id))),
              icon: const Icon(Icons.comment_outlined),
              label: Text('${post.commentCount}'),
            ),
          ]),
        ]),
      ),
    );
  }
}
