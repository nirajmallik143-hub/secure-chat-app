import 'package:flutter/material.dart';

/// Nepal-inspired palette: crimson red and deep blue (from the national flag).
class AppColors {
  static const crimson = Color(0xFFDC143C);
  static const blue = Color(0xFF003893);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.crimson,
    primary: AppColors.crimson,
    secondary: AppColors.blue,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.crimson, foregroundColor: Colors.white),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(backgroundColor: AppColors.blue, foregroundColor: Colors.white),
    navigationBarTheme: NavigationBarThemeData(indicatorColor: AppColors.blue.withOpacity(0.15)),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: AppColors.crimson)),
  );
}
