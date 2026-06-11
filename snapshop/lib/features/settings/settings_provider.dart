import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/network/api_client.dart' show ApiClient, AppException;
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

  String get displayName => label;

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

@immutable
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
  final Set<String> favoriteProductIds;

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
    this.favoriteProductIds = const <String>{},
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
    Set<String>? favoriteProductIds,
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
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsState &&
          runtimeType == other.runtimeType &&
          localeOption == other.localeOption &&
          themeModeOption == other.themeModeOption &&
          fontSizeOption == other.fontSizeOption &&
          pushEnabled == other.pushEnabled &&
          inAppAlertsEnabled == other.inAppAlertsEnabled &&
          avatarPath == other.avatarPath &&
          nickname == other.nickname &&
          bio == other.bio &&
          isLoggedIn == other.isLoggedIn &&
          favoriteCount == other.favoriteCount &&
          browseCount == other.browseCount &&
          favoriteProductIds == other.favoriteProductIds;

  @override
  int get hashCode => Object.hash(
        localeOption,
        themeModeOption,
        fontSizeOption,
        pushEnabled,
        inAppAlertsEnabled,
        avatarPath,
        nickname,
        bio,
        isLoggedIn,
        favoriteCount,
        browseCount,
        favoriteProductIds,
      );

  @override
  String toString() =>
      'SettingsState(locale: $localeOption, theme: $themeModeOption, fontSize: $fontSizeOption, isLoggedIn: $isLoggedIn)';
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _localeKey = 'app_locale';
  static const _themeModeKey = 'theme_mode';
  static const _fontSizeKey = 'font_size';
  static const _pushEnabledKey = 'push_enabled';
  static const _inAppAlertsEnabledKey = 'inapp_alerts_enabled';
  static const _avatarKey = 'profile_avatar';
  static const _nicknameKey = 'profile_nickname';
  static const _bioKey = 'profile_bio';
  static const _isLoggedInKey = 'is_logged_in';

  @override
  SettingsState build() {
    _loadFromPrefs();
    return const SettingsState(
      localeOption: LocaleOption.zh,
      themeModeOption: ThemeModeOption.system,
      fontSizeOption: FontSizeOption.standard,
    );
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await ApiClient.loadToken();

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

    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
    if (!isLoggedIn) {
      prefs.remove(_nicknameKey);
      prefs.remove(_bioKey);
      prefs.remove(_avatarKey);
    }
    state = SettingsState(
      localeOption: localeOption,
      themeModeOption: themeModeOption,
      fontSizeOption: fontSizeOption,
      pushEnabled: prefs.getBool(_pushEnabledKey) ?? true,
      inAppAlertsEnabled: prefs.getBool(_inAppAlertsEnabledKey) ?? true,
      avatarPath: isLoggedIn ? prefs.getString(_avatarKey) : null,
      nickname: isLoggedIn ? (prefs.getString(_nicknameKey) ?? 'SnapShop 用户') : 'SnapShop 用户',
      bio: isLoggedIn ? (prefs.getString(_bioKey) ?? '') : '',
      isLoggedIn: isLoggedIn,
    );
    if (isLoggedIn) {
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

  Future<void> refreshStats() async {
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
      debugPrint('[SettingsProvider] refreshStats 失败: $e');
    }
  }

  Future<void> _loadStats() async {
    await refreshStats();
  }

  void addFavoriteId(String productId) {
    state = state.copyWith(favoriteProductIds: {...state.favoriteProductIds, productId});
  }

  void removeFavoriteId(String productId) {
    final updated = Set<String>.from(state.favoriteProductIds);
    updated.remove(productId);
    state = state.copyWith(favoriteProductIds: updated);
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final api = ApiClient();
      final response = await api.get('/favorites');
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        final items = raw['items'];
        if (items is List) {
          final ids = <String>{};
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final pid = item['product_id']?.toString();
              if (pid != null) ids.add(pid);
            }
          }
          state = state.copyWith(favoriteProductIds: ids);
        }
      }
    } catch (e) {
      debugPrint('[SettingsProvider] _loadFavoriteIds 失败: $e');
    }
  }

  Future<String?> setProfile(String? avatarPath, String nickname, String bio) async {
    final prefs = await SharedPreferences.getInstance();
    if (avatarPath != null) {
      await prefs.setString(_avatarKey, avatarPath);
    }
    await prefs.setString(_nicknameKey, nickname);
    await prefs.setString(_bioKey, bio);
    state = state.copyWith(
      avatarPath: avatarPath ?? state.avatarPath,
      nickname: nickname,
      bio: bio,
    );

    if (state.isLoggedIn) {
      try {
        final api = ApiClient();
        await api.patch('/auth/profile', data: {
          'nickname': nickname,
          'bio': bio,
        });
      } catch (e) {
        debugPrint('[SettingsProvider] 同步个人信息到服务器失败: $e');
      }
    }
    return null;
  }

  String _handleAuthError(DioException e, String fallback) {
    if (e.error is AppException) {
      return (e.error as AppException).message;
    }
    if (e.response != null) {
      final detail = e.response!.data;
      if (detail is Map<String, dynamic>) {
        final msg = detail['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return '连接超时：服务器无响应，请确认后端已启动';
    }
    if (e.type == DioExceptionType.connectionError) {
      return '无法连接：请确认手机USB已连接且运行了 adb reverse';
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return '响应超时：请求已发出但服务器处理过慢';
    }
    return '$fallback（网络错误）';
  }

  Future<String?> _authRequest(String endpoint, String phone, String password) async {
    final api = ApiClient();
    try {
      final response = await api.post(endpoint, data: {
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
      _loadFavoriteIds();
      return null;
    } on DioException catch (e) {
      return _handleAuthError(e, endpoint == '/auth/login' ? '登录失败' : '注册失败');
    } catch (e) {
      return '${endpoint == '/auth/login' ? '登录' : '注册'}失败：$e';
    }
  }

  Future<String?> login(String phone, String password) async {
    return _authRequest('/auth/login', phone, password);
  }

  Future<String?> register(String phone, String password, String passwordConfirm) async {
    final api = ApiClient();
    try {
      final response = await api.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'password_confirm': passwordConfirm,
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
      _loadFavoriteIds();
      return null;
    } on DioException catch (e) {
      return _handleAuthError(e, '注册失败');
    } catch (e) {
      return '注册失败：$e';
    }
  }

  Future<String?> smsLogin(String phone, String code) async {
    final api = ApiClient();
    try {
      final response = await api.post('/auth/sms-login', data: {
        'phone': phone,
        'code': code,
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
      _loadFavoriteIds();
      return null;
    } on DioException catch (e) {
      return _handleAuthError(e, '验证码登录失败');
    } catch (e) {
      return '验证码登录失败：$e';
    }
  }

  Future<void> logout() async {
    try {
      final api = ApiClient();
      await api.post('/auth/logout');
    } catch (_) {}
    await ApiClient.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_nicknameKey);
    await prefs.remove(_bioKey);
    await prefs.remove(_avatarKey);
    state = SettingsState(
      localeOption: state.localeOption,
      themeModeOption: state.themeModeOption,
      fontSizeOption: state.fontSizeOption,
      pushEnabled: state.pushEnabled,
      inAppAlertsEnabled: state.inAppAlertsEnabled,
      favoriteProductIds: const <String>{},
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  () => SettingsNotifier(),
);

final localeProvider = Provider<LocaleOption>((ref) {
  return ref.watch(settingsProvider.select((state) => state.localeOption));
});

final themeModeProvider = Provider<ThemeModeOption>((ref) {
  return ref.watch(settingsProvider.select((state) => state.themeModeOption));
});

final fontSizeProvider = Provider<FontSizeOption>((ref) {
  return ref.watch(settingsProvider.select((state) => state.fontSizeOption));
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider.select((state) => state.isLoggedIn));
});

final nicknameProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider.select((state) => state.nickname));
});

final statsProvider = Provider<(int, int)>((ref) {
  final state = ref.watch(settingsProvider);
  return (state.favoriteCount, state.browseCount);
});
