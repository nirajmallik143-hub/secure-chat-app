import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';

class AuthState {
  const AuthState({this.user, this.restored = false, this.loading = false, this.error});
  final Map<String, dynamic>? user;
  final bool restored;
  final bool loading;
  final String? error;

  String? get userId => user?['id'] as String?;
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api) : super(const AuthState());
  final ApiClient _api;

  Future<void> restore() async {
    if (await _api.tokens.access == null) {
      state = const AuthState(restored: true);
      return;
    }
    try {
      final res = await _api.dio.get('/users/me');
      state = AuthState(user: res.data['user'], restored: true);
    } catch (_) {
      await _api.tokens.clear();
      state = const AuthState(restored: true);
    }
  }

  Future<bool> _submit(String path, Map<String, dynamic> body) async {
    state = AuthState(restored: true, loading: true, user: state.user);
    try {
      final res = await _api.dio.post(path, data: body);
      await _api.tokens.save(res.data['accessToken'], res.data['refreshToken']);
      state = AuthState(user: res.data['user'], restored: true);
      return true;
    } catch (e) {
      state = const AuthState(restored: true, error: 'error');
      return false;
    }
  }

  static Map<String, dynamic> _identifier(String value) {
    final v = value.trim();
    return v.contains('@') ? {'email': v} : {'phone': v};
  }

  Future<bool> login(String identifier, String password) =>
      _submit('/auth/login', {..._identifier(identifier), 'password': password});

  Future<bool> signup(String identifier, String password, String name) =>
      _submit('/auth/signup', {..._identifier(identifier), 'password': password, 'displayName': name});

  Future<void> logout() async {
    final rt = await _api.tokens.refresh;
    if (rt != null) {
      try {
        await _api.dio.post('/auth/logout', data: {'refreshToken': rt});
      } catch (_) {}
    }
    await _api.tokens.clear();
    state = const AuthState(restored: true);
  }

  /// Permanently deletes the account on the server (required by Google Play & Apple).
  Future<void> deleteAccount() async {
    await _api.dio.delete('/auth/account');
    await _api.tokens.clear();
    state = const AuthState(restored: true);
  }

  void updateUser(Map<String, dynamic> user) =>
      state = AuthState(user: {...?state.user, ...user}, restored: true);
}

final authProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) => AuthController(ref.read(apiProvider)));
