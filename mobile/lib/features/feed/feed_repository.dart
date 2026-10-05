import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class Post {
  Post(this.json);
  final Map<String, dynamic> json;
  String get id => json['id'];
  String get text => json['text'];
  String? get imageUrl => json['imageUrl'];
  String get authorId => json['author']['id'];
  String get authorName => json['author']['displayName'];
  int get likes => json['_count']['likes'];
  int get commentCount => json['_count']['comments'];
  bool get likedByMe => json['likedByMe'] == true;
}

class FeedRepository {
  FeedRepository(this._dio);
  final Dio _dio;

  Future<List<Post>> feed() async {
    final res = await _dio.get('/posts');
    return (res.data['posts'] as List).map((p) => Post(p)).toList();
  }

  Future<String> uploadImage(File file) async {
    final form = FormData.fromMap({'image': await MultipartFile.fromFile(file.path)});
    final res = await _dio.post('/posts/upload', data: form);
    return res.data['url'];
  }

  Future<void> create(String text, {String? imageUrl}) =>
      _dio.post('/posts', data: {'text': text, if (imageUrl != null) 'imageUrl': imageUrl});

  Future<void> toggleLike(String id) => _dio.post('/posts/$id/like');

  Future<List<Map<String, dynamic>>> comments(String id) async {
    final res = await _dio.get('/posts/$id/comments');
    return List<Map<String, dynamic>>.from(res.data['comments']);
  }

  Future<void> addComment(String id, String text) => _dio.post('/posts/$id/comments', data: {'text': text});

  Future<void> report({String? postId, String? userId, required String reason}) =>
      _dio.post('/reports', data: {if (postId != null) 'postId': postId, if (userId != null) 'reportedUserId': userId, 'reason': reason});

  Future<void> block(String userId) => _dio.post('/users/$userId/block');
}

final feedRepositoryProvider = Provider((ref) => FeedRepository(ref.read(apiProvider).dio));
final feedProvider = FutureProvider.autoDispose<List<Post>>((ref) => ref.read(feedRepositoryProvider).feed());
