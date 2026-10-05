import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.restored) {
      return auth.user != null ? const HomeScreen() : const AuthScreen();
    }
    return Scaffold(
      backgroundColor: AppColors.crimson,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.groups_rounded, size: 96, color: Colors.white),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).appName,
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
