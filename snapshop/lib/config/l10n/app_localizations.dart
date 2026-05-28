import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedStrings = <String, Map<String, String>>{
    // ── Settings page ──
    'settings_title': {'zh': '设置', 'en': 'Settings'},
    'settings_account': {'zh': '账户', 'en': 'Account'},
    'settings_preferences': {'zh': '偏好', 'en': 'Preferences'},
    'settings_about': {'zh': '关于', 'en': 'About'},
    'settings_personal_info': {'zh': '个人信息', 'en': 'Personal Info'},
    'settings_personal_info_desc': {
      'zh': '头像、昵称、简介',
      'en': 'Avatar, Nickname, Bio'
    },
    'settings_account_security': {'zh': '账号安全', 'en': 'Account Security'},
    'settings_account_security_desc': {
      'zh': '密码、绑定手机',
      'en': 'Password, Phone Binding'
    },
    'settings_notifications': {'zh': '消息通知', 'en': 'Notifications'},
    'settings_notifications_desc': {
      'zh': '推送、提醒设置',
      'en': 'Push, Alert Settings'
    },
    'settings_language': {'zh': '语言', 'en': 'Language'},
    'settings_appearance': {'zh': '外观', 'en': 'Appearance'},
    'settings_appearance_value': {'zh': '跟随系统', 'en': 'Follow System'},
    'settings_font_size': {'zh': '字体大小', 'en': 'Font Size'},
    'settings_font_size_value': {'zh': '默认', 'en': 'Default'},
    'settings_clear_cache': {'zh': '清理缓存', 'en': 'Clear Cache'},
    'settings_check_update': {'zh': '检查更新', 'en': 'Check Update'},
    'settings_user_agreement': {'zh': '用户协议', 'en': 'User Agreement'},
    'settings_privacy_policy': {'zh': '隐私政策', 'en': 'Privacy Policy'},
    'settings_logout': {'zh': '退出登录', 'en': 'Log Out'},
    'settings_profile_name': {'zh': 'SnapShop 用户', 'en': 'SnapShop User'},
    'settings_favorites': {'zh': '收藏', 'en': 'Favorites'},
    'settings_footprints': {'zh': '足迹', 'en': 'Footprints'},

    // ── Loading ──
    'loading_title': {'zh': 'AI 视觉识别中...', 'en': 'AI Visual Recognition...'},
    'loading_subtitle': {
      'zh': '正在提取商品属性及全网比价',
      'en': 'Extracting product attributes and comparing prices'
    },

    // ── Error retry ──
    'retry': {'zh': '重试', 'en': 'Retry'},

    // ── Browse / Search history ──
    'browse_history': {'zh': '浏览记录', 'en': 'Browse History'},
    'search_history': {'zh': '搜索记录', 'en': 'Search History'},
    'history_title': {'zh': '历史记录', 'en': 'History'},

    // ── Home page ──
    'home_slogan': {
      'zh': '拍照识物 · 智能比价',
      'en': 'Snap & Shop · Smart Compare'
    },

    // ── Search bar ──
    'search_placeholder': {'zh': '搜索商品...', 'en': 'Search products...'},

    // ── Gallery picker ──
    'gallery_permission_title': {
      'zh': '需要相册访问权限',
      'en': 'Photo Library Access Required'
    },
    'gallery_permission_grant': {'zh': '授权', 'en': 'Grant Access'},
    'gallery_empty': {
      'zh': '相册中没有照片',
      'en': 'No photos in gallery'
    },
    'gallery_title': {'zh': '相册', 'en': 'Gallery'},

    // ── Recognition page ──
    'recognition_title': {'zh': '识别结果', 'en': 'Recognition Result'},
    'recognition_empty': {
      'zh': '暂未找到相关商品，试试修改关键词吧',
      'en': 'No matching products found, try different keywords'
    },
    'recognition_ai_label': {'zh': 'AI 识别为 ', 'en': 'AI recognized as '},

    // ── Attribute edit sheet ──
    'attribute_edit_title': {'zh': '修正属性', 'en': 'Edit Attribute'},
    'attribute_edit_hint': {'zh': '请输入', 'en': 'Please enter '},
    'attribute_edit_tip': {
      'zh': '修正后，AI 会重新检索更精准的商品结果',
      'en': 'After editing, AI will re-search for more accurate results'
    },
    'attribute_edit_confirm': {'zh': '确认修改', 'en': 'Confirm'},

    // ── Filter input ──
    'filter_placeholder': {
      'zh': '自然语言筛选，如「500元以内自营」',
      'en': 'Natural language filter, e.g. "under 500 self-operated"'
    },

    // ── Sort bar ──
    'sort_comprehensive': {'zh': '综合推荐', 'en': 'Recommended'},
    'sort_price_asc': {'zh': '价格从低到高', 'en': 'Price: Low to High'},
    'sort_sales': {'zh': '销量优先', 'en': 'Best Selling'},

    // ── Price summary bar ──
    'price_all_platforms': {'zh': '全网 ', 'en': 'All platforms '},
    'price_items_found': {'zh': ' 款同款', 'en': ' items found'},
    'price_lowest': {'zh': '最低价', 'en': 'Lowest'},
    'price_average': {'zh': '均价', 'en': 'Average'},
  };

  String get(String key) {
    final langCode = locale.languageCode == 'zh' ? 'zh' : 'en';
    return _localizedStrings[key]?[langCode] ?? key;
  }

  String pleaseEnter(String attribute) {
    final prefix = get('attribute_edit_hint');
    return '$prefix$attribute';
  }

  String formatSalesCount(int count) {
    final isZh = locale.languageCode == 'zh';
    if (count > 10000) {
      final value = (count / 10000).toStringAsFixed(1);
      return isZh ? '已售 $value万' : '${(count / 1000).toStringAsFixed(1)}K sold';
    }
    return isZh ? '已售 $count' : '$count sold';
  }

  // ── Getters ──

  // Settings
  String get settingsTitle => get('settings_title');
  String get settingsAccount => get('settings_account');
  String get settingsPreferences => get('settings_preferences');
  String get settingsAbout => get('settings_about');
  String get settingsPersonalInfo => get('settings_personal_info');
  String get settingsPersonalInfoDesc => get('settings_personal_info_desc');
  String get settingsAccountSecurity => get('settings_account_security');
  String get settingsAccountSecurityDesc => get('settings_account_security_desc');
  String get settingsNotifications => get('settings_notifications');
  String get settingsNotificationsDesc => get('settings_notifications_desc');
  String get settingsLanguage => get('settings_language');
  String get settingsAppearance => get('settings_appearance');
  String get settingsAppearanceValue => get('settings_appearance_value');
  String get settingsFontSize => get('settings_font_size');
  String get settingsFontSizeValue => get('settings_font_size_value');
  String get settingsClearCache => get('settings_clear_cache');
  String get settingsCheckUpdate => get('settings_check_update');
  String get settingsUserAgreement => get('settings_user_agreement');
  String get settingsPrivacyPolicy => get('settings_privacy_policy');
  String get settingsLogout => get('settings_logout');
  String get settingsProfileName => get('settings_profile_name');
  String get settingsFavorites => get('settings_favorites');
  String get settingsFootprints => get('settings_footprints');

  // Loading
  String get loadingTitle => get('loading_title');
  String get loadingSubtitle => get('loading_subtitle');

  // Error
  String get retry => get('retry');

  // History
  String get browseHistory => get('browse_history');
  String get searchHistory => get('search_history');
  String get historyTitle => get('history_title');

  // Home
  String get homeSlogan => get('home_slogan');

  // Search
  String get searchPlaceholder => get('search_placeholder');

  // Gallery
  String get galleryPermissionTitle => get('gallery_permission_title');
  String get galleryPermissionGrant => get('gallery_permission_grant');
  String get galleryEmpty => get('gallery_empty');
  String get galleryTitle => get('gallery_title');

  // Recognition
  String get recognitionTitle => get('recognition_title');
  String get recognitionEmpty => get('recognition_empty');
  String get recognitionAiLabel => get('recognition_ai_label');

  // Attribute edit
  String get attributeEditTitle => get('attribute_edit_title');
  String get attributeEditHint => get('attribute_edit_hint');
  String get attributeEditTip => get('attribute_edit_tip');
  String get attributeEditConfirm => get('attribute_edit_confirm');

  // Filter
  String get filterPlaceholder => get('filter_placeholder');

  // Sort
  String get sortComprehensive => get('sort_comprehensive');
  String get sortPriceAsc => get('sort_price_asc');
  String get sortSales => get('sort_sales');

  // Price
  String get priceAllPlatforms => get('price_all_platforms');
  String get priceItemsFound => get('price_items_found');
  String get priceLowest => get('price_lowest');
  String get priceAverage => get('price_average');
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
