import 'package:flutter_test/flutter_test.dart';
import 'package:nepalconnect/features/auth/auth_controller.dart';

void main() {
  test('AuthState exposes the user id', () {
    const state = AuthState(user: {'id': 'abc'}, restored: true);
    expect(state.userId, 'abc');
  });
}
