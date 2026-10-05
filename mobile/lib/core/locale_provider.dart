import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('locale');
    if (code != null) state = Locale(code);
  }

  Future<void> toggle() async {
    state = state.languageCode == 'en' ? const Locale('ne') : const Locale('en');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', state.languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController());
