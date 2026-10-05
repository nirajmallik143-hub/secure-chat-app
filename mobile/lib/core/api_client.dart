import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'config.dart';

const _storage = FlutterSecureStorage();

class TokenStore {
  Future<String?> get access => _storage.read(key: 'access');
  Future<String?> get refresh => _storage.read(key: 'refresh');
  Future<void> save(String access, String refresh) async {
    await _storage.write(key: 'access', value: access);
    await _storage.write(key: 'refresh', value: refresh);
  }

  Future<void> clear() async {
    await _storage.delete(key: 'access');
    await _storage.delete(key: 'refresh');
  }
}

class ApiClient {
  ApiClient() : dio = Dio(BaseOptions(baseUrl: '$apiUrl/api', connectTimeout: const Duration(seconds: 15))) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokens.access;
        if (token != null) options.headers['Authorization'] = 'Bearer ' + token;
        handler.next(options);
      },
      onError: (e, handler) async {
        final req = e.requestOptions;
        if (e.response?.statusCode == 401 && req.extra['retried'] != true && !req.path.startsWith('/auth/')) {
          if (await _refresh()) {
            req.extra['retried'] = true;
            req.headers['Authorization'] = 'Bearer ' + (await tokens.access ?? '');
            try {
              return handler.resolve(await dio.fetch(req));
            } on DioException catch (err) {
              return handler.next(err);
            }
          }
        }
        handler.next(e);
      },
    ));
  }

  final Dio dio;
  final tokens = TokenStore();

  Future<bool> _refresh() async {
    final rt = await tokens.refresh;
    if (rt == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: '$apiUrl/api')).post('/auth/refresh', data: {'refreshToken': rt});
      await tokens.save(res.data['accessToken'], res.data['refreshToken']);
      return true;
    } catch (_) {
      await tokens.clear();
      return false;
    }
  }
}

final apiProvider = Provider<ApiClient>((ref) => ApiClient());
