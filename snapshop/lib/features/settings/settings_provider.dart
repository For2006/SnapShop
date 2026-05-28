import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocaleOption {
  zh,
  en;

  Locale get locale {
    switch (this) {
      case LocaleOption.zh:
        return const Locale('zh', 'CN');
      case LocaleOption.en:
        return const Locale('en', 'US');
    }
  }

  String get label {
    switch (this) {
      case LocaleOption.zh:
        return '简体中文';
      case LocaleOption.en:
        return 'English';
    }
  }

  String get displayName {
    switch (this) {
      case LocaleOption.zh:
        return '简体中文';
      case LocaleOption.en:
        return 'English';
    }
  }

  static LocaleOption fromLocale(Locale locale) {
    if (locale.languageCode == 'zh') return LocaleOption.zh;
    return LocaleOption.en;
  }
}

class SettingsState {
  final LocaleOption localeOption;

  const SettingsState({required this.localeOption});

  SettingsState copyWith({LocaleOption? localeOption}) {
    return SettingsState(
      localeOption: localeOption ?? this.localeOption,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _localeKey = 'app_locale';

  SettingsNotifier() : super(const SettingsState(localeOption: LocaleOption.zh)) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_localeKey);
    if (stored != null) {
      final option = LocaleOption.values.firstWhere(
        (e) => e.name == stored,
        orElse: () => LocaleOption.zh,
      );
      state = SettingsState(localeOption: option);
    }
  }

  Future<void> setLocale(LocaleOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, option.name);
    state = SettingsState(localeOption: option);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
