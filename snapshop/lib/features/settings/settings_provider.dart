import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import 'package:dio/dio.dart';

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

enum ThemeModeOption {
  light,
  dark,
  system;

  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case ThemeModeOption.light:
        return l10n.appearanceLight;
      case ThemeModeOption.dark:
        return l10n.appearanceDark;
      case ThemeModeOption.system:
        return l10n.appearanceSystem;
    }
  }
}

enum FontSizeOption {
  small,
  standard,
  large;

  double get scale {
    switch (this) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.standard:
        return 1.0;
      case FontSizeOption.large:
        return 1.15;
    }
  }

  String label(AppLocalizations l10n) {
    switch (this) {
      case FontSizeOption.small:
        return l10n.fontSizeSmall;
      case FontSizeOption.standard:
        return l10n.fontSizeStandard;
      case FontSizeOption.large:
        return l10n.fontSizeLarge;
    }
  }
}

class SettingsState {
  final LocaleOption localeOption;
  final ThemeModeOption themeModeOption;
  final FontSizeOption fontSizeOption;
  final bool pushEnabled;
  final bool inAppAlertsEnabled;
  final String? avatarPath;
  final String nickname;
  final String bio;
  final bool isLoggedIn;
  final int favoriteCount;
  final int browseCount;

  const SettingsState({
    required this.localeOption,
    required this.themeModeOption,
    required this.fontSizeOption,
    this.pushEnabled = true,
    this.inAppAlertsEnabled = true,
    this.avatarPath,
    this.nickname = 'SnapShop 用户',
    this.bio = '',
    this.isLoggedIn = false,
    this.favoriteCount = 0,
    this.browseCount = 0,
  });

  SettingsState copyWith({
    LocaleOption? localeOption,
    ThemeModeOption? themeModeOption,
    FontSizeOption? fontSizeOption,
    bool? pushEnabled,
    bool? inAppAlertsEnabled,
    String? avatarPath,
    String? nickname,
    String? bio,
    bool? isLoggedIn,
    int? favoriteCount,
    int? browseCount,
  }) {
    return SettingsState(
      localeOption: localeOption ?? this.localeOption,
      themeModeOption: themeModeOption ?? this.themeModeOption,
      fontSizeOption: fontSizeOption ?? this.fontSizeOption,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppAlertsEnabled: inAppAlertsEnabled ?? this.inAppAlertsEnabled,
      avatarPath: avatarPath ?? this.avatarPath,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      browseCount: browseCount ?? this.browseCount,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const _localeKey = 'app_locale';
  static const _themeModeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _pushEnabledKey = 'push_enabled';
  static const _inAppAlertsEnabledKey = 'inapp_alerts_enabled';
  static const _avatarKey = 'profile_avatar';
  static const _nicknameKey = 'profile_nickname';
  static const _bioKey = 'profile_bio';
  static const _isLoggedInKey = 'is_logged_in';

  SettingsNotifier()
      : super(const SettingsState(
          localeOption: LocaleOption.zh,
          themeModeOption: ThemeModeOption.system,
          fontSizeOption: FontSizeOption.standard,
        )) {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final storedLocale = prefs.getString(_localeKey);
    final localeOption = storedLocale != null
        ? LocaleOption.values.firstWhere(
            (e) => e.name == storedLocale,
            orElse: () => LocaleOption.zh,
          )
        : LocaleOption.zh;

    final storedTheme = prefs.getString(_themeModeKey);
    final themeModeOption = storedTheme != null
        ? ThemeModeOption.values.firstWhere(
            (e) => e.name == storedTheme,
            orElse: () => ThemeModeOption.system,
          )
        : ThemeModeOption.system;

    final storedFontSize = prefs.getString(_fontSizeKey);
    final fontSizeOption = storedFontSize != null
        ? FontSizeOption.values.firstWhere(
            (e) => e.name == storedFontSize,
            orElse: () => FontSizeOption.standard,
          )
        : FontSizeOption.standard;

    state = SettingsState(
      localeOption: localeOption,
      themeModeOption: themeModeOption,
      fontSizeOption: fontSizeOption,
      pushEnabled: prefs.getBool(_pushEnabledKey) ?? true,
      inAppAlertsEnabled: prefs.getBool(_inAppAlertsEnabledKey) ?? true,
      avatarPath: prefs.getString(_avatarKey),
      nickname: prefs.getString(_nicknameKey) ?? 'SnapShop 用户',
      bio: prefs.getString(_bioKey) ?? '',
      isLoggedIn: prefs.getBool(_isLoggedInKey) ?? false,
    );
    if (prefs.getBool(_isLoggedInKey) ?? false) {
      _loadStats();
    }
  }

  Future<void> setLocale(LocaleOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, option.name);
    state = state.copyWith(localeOption: option);
  }

  Future<void> setThemeMode(ThemeModeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, option.name);
    state = state.copyWith(themeModeOption: option);
  }

  Future<void> setFontSize(FontSizeOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, option.name);
    state = state.copyWith(fontSizeOption: option);
  }

  Future<void> setPushEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushEnabledKey, value);
    state = state.copyWith(pushEnabled: value);
  }

  Future<void> setInAppAlertsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_inAppAlertsEnabledKey, value);
    state = state.copyWith(inAppAlertsEnabled: value);
  }

  Future<void> _loadStats() async {
    try {
      final api = ApiClient();
      final response = await api.get('/user/stats');
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        debugPrint('[SettingsProvider] 响应格式异常: ${raw.runtimeType}');
        return;
      }
      final data = raw;
      state = state.copyWith(
        favoriteCount: (data['favorite_count'] ?? 0).toInt(),
        browseCount: (data['browse_count'] ?? 0).toInt(),
      );
    } catch (e) {
      debugPrint('[SettingsProvider] _loadStats 失败: $e');
    }
  }

  Future<void> setProfile(String? avatarPath, String nickname, String bio) async {
    final prefs = await SharedPreferences.getInstance();
    if (avatarPath != null) {
      await prefs.setString(_avatarKey, avatarPath);
    }
    await prefs.setString(_nicknameKey, nickname);
    await prefs.setString(_bioKey, bio);
    state = state.copyWith(avatarPath: avatarPath, nickname: nickname, bio: bio);
  }

  Future<String?> login(String phone, String password) async {
    final api = ApiClient();
    try {
      final response = await api.post('/auth/login', data: {
        'phone': phone,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await ApiClient.setToken(token);
      final user = data['user'] as Map<String, dynamic>;
      final nickname = user['nickname']?.toString() ?? phone;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_nicknameKey, nickname);
      state = state.copyWith(isLoggedIn: true, nickname: nickname);
      _loadStats();
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response!.data;
        if (detail is Map<String, dynamic>) {
          return detail['message']?.toString() ?? '登录失败';
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '网络连接超时，请检查网络后重试';
      }
      if (e.type == DioExceptionType.connectionError) {
        return '无法连接服务器，请检查网络后重试';
      }
      return '登录失败（网络错误）';
    } catch (e) {
      return '登录失败：$e';
    }
  }

  Future<String?> register(String phone, String password) async {
    final api = ApiClient();
    try {
      final response = await api.post('/auth/register', data: {
        'phone': phone,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await ApiClient.setToken(token);
      final user = data['user'] as Map<String, dynamic>;
      final nickname = user['nickname']?.toString() ?? phone;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setString(_nicknameKey, nickname);
      state = state.copyWith(isLoggedIn: true, nickname: nickname);
      _loadStats();
      return null;
    } on DioException catch (e) {
      if (e.response != null) {
        final detail = e.response!.data;
        if (detail is Map<String, dynamic>) {
          return detail['message']?.toString() ?? '注册失败';
        }
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return '网络连接超时，请检查网络后重试';
      }
      if (e.type == DioExceptionType.connectionError) {
        return '无法连接服务器，请检查网络后重试';
      }
      return '注册失败（网络错误）';
    } catch (e) {
      return '注册失败：$e';
    }
  }

  Future<void> logout() async {
    await ApiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_avatarKey);
    await prefs.remove(_nicknameKey);
    await prefs.remove(_bioKey);
    await prefs.setBool(_isLoggedInKey, false);
    state = state.copyWith(
      isLoggedIn: false,
      avatarPath: null,
      nickname: 'SnapShop 用户',
      bio: '',
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(),
);
