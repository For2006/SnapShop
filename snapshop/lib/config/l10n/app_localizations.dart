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
    'no_favorites': {'zh': '暂无收藏', 'en': 'No favorites yet'},
    'no_browse_history': {'zh': '暂无浏览记录', 'en': 'No browsing history'},
    'browse_clear_title': {'zh': '清空足迹', 'en': 'Clear History'},
    'browse_clear_message': {'zh': '确定要清空所有浏览记录吗？此操作不可恢复。', 'en': 'Clear all browsing history? This cannot be undone.'},
    'browse_delete_item': {'zh': '删除此条记录', 'en': 'Delete this record'},

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
    'sort_price_desc': {'zh': '价格从高到低', 'en': 'Price: High to Low'},
    'sort_sales': {'zh': '销量优先', 'en': 'Best Selling'},
    'sort_rating': {'zh': '好评率优先', 'en': 'Top Rated'},

    // ── Price summary bar ──
    'price_all_platforms': {'zh': '全网 ', 'en': 'All platforms '},
    'price_items_found': {'zh': ' 款同款', 'en': ' items found'},
    'price_lowest': {'zh': '最低价', 'en': 'Lowest'},
    'price_average': {'zh': '均价', 'en': 'Average'},

    'appearance_light': {'zh': '浅色模式', 'en': 'Light Mode'},
    'appearance_dark': {'zh': '深色模式', 'en': 'Dark Mode'},
    'appearance_system': {'zh': '跟随系统', 'en': 'Follow System'},
    'font_size_small': {'zh': '小', 'en': 'Small'},
    'font_size_standard': {'zh': '标准', 'en': 'Standard'},
    'font_size_large': {'zh': '大', 'en': 'Large'},
    'font_size_preview': {'zh': '预览效果', 'en': 'Preview'},

    // ── Cache ──
    'cache_clear_title': {'zh': '确认清理', 'en': 'Confirm Clear'},
    'cache_clear_message': {'zh': '确定要清理应用缓存吗？', 'en': 'Are you sure you want to clear the app cache?'},
    'cache_confirm': {'zh': '确认', 'en': 'Confirm'},
    'cache_cancel': {'zh': '取消', 'en': 'Cancel'},
    'cache_cleared': {'zh': '已清理', 'en': 'Cleared'},

    // ── Notification preferences ──
    'notif_push_title': {'zh': '推送通知', 'en': 'Push Notifications'},
    'notif_inapp_title': {'zh': '应用内提醒', 'en': 'In-App Alerts'},

    // ── Profile edit ──
    'profile_edit_title': {'zh': '编辑个人信息', 'en': 'Edit Profile'},
    'profile_nickname': {'zh': '昵称', 'en': 'Nickname'},
    'profile_bio': {'zh': '简介', 'en': 'Bio'},
    'profile_bio_hint': {'zh': '介绍一下自己...', 'en': 'Tell us about yourself...'},
    'profile_save': {'zh': '保存', 'en': 'Save'},
    'profile_save_success': {'zh': '个人信息已保存', 'en': 'Profile saved'},
    'profile_avatar_hint': {'zh': '点击更换头像', 'en': 'Tap to change avatar'},

    // ── Login page ──
    'login_title': {'zh': '登录', 'en': 'Login'},
    'login_phone_hint': {'zh': '请输入手机号', 'en': 'Enter phone number'},
    'login_password_hint': {'zh': '请输入密码', 'en': 'Enter password'},
    'login_button': {'zh': '登录', 'en': 'Login'},
    'login_no_account': {'zh': '没有账号？', 'en': "Don't have an account? "},
    'login_register': {'zh': '注册', 'en': 'Register'},
    'register_title': {'zh': '注册', 'en': 'Register'},
    'register_button': {'zh': '注册', 'en': 'Register'},
    'login_have_account': {'zh': '已有账号？', 'en': 'Already have an account? '},
    'login_back': {'zh': '返回登录', 'en': 'Login'},
    'login_phone_error': {'zh': '请输入11位手机号', 'en': 'Please enter an 11-digit phone number'},
    'login_sms_sent_debug': {'zh': '验证码已发送（开发环境可从后端日志查看）', 'en': 'Code sent (check backend log in dev mode)'},
    'login_send_sms_failed': {'zh': '发送验证码失败', 'en': 'Failed to send SMS code'},
    'login_sms_code_error': {'zh': '请输入6位验证码', 'en': 'Please enter the 6-digit code'},
    'login_password_tab': {'zh': '密码登录', 'en': 'Password Login'},
    'login_sms_tab': {'zh': '短信验证码登录', 'en': 'SMS Login'},
    'login_sms_code_hint': {'zh': '请输入验证码', 'en': 'Enter verification code'},
    'login_get_code': {'zh': '获取验证码', 'en': 'Get Code'},
    'login_sms_button': {'zh': '验证码登录', 'en': 'SMS Login'},
    'register_password_confirm_hint': {'zh': '请再次输入密码', 'en': 'Confirm password'},
    'register_password_mismatch': {'zh': '两次输入的密码不一致', 'en': 'Passwords do not match'},

    // ── Logout ──
    'logout_title': {'zh': '退出登录', 'en': 'Log Out'},
    'logout_message': {'zh': '确定要退出登录吗？', 'en': 'Are you sure you want to log out?'},
    'logout_confirm': {'zh': '确定', 'en': 'Confirm'},
    'logout_cancel': {'zh': '取消', 'en': 'Cancel'},

    // ── Error messages ──
    'recognition_failed': {
      'zh': '识别失败，请检查网络后重试',
      'en': 'Recognition failed, check your network and try again'
    },
    'search_failed': {
      'zh': '搜索失败，请检查网络后重试',
      'en': 'Search failed, check your network and try again'
    },
    'filter_no_session': {
      'zh': '请先进行识图识别',
      'en': 'Please perform image recognition first'
    },
    'filter_network_error': {
      'zh': '筛选失败，请检查网络后重试',
      'en': 'Filter failed, check your network and try again'
    },
    'filter_empty_result': {
      'zh': '没有符合条件的商品，试试放宽筛选条件',
      'en': 'No products match, try relaxing your filters'
    },
    'filter_clear_all': {
      'zh': '清空',
      'en': 'Clear all'
    },
    'login_failed': {'zh': '登录失败', 'en': 'Login failed'},
    'register_failed': {'zh': '注册失败', 'en': 'Registration failed'},
    'no_search_history': {'zh': '暂无搜索记录', 'en': 'No search history'},
    'history_login_prompt': {
      'zh': '登录后查看搜索历史',
      'en': 'Log in to view search history'
    },
    'history_login_button': {'zh': '立即登录', 'en': 'Log In Now'},
    'snapshop_user': {'zh': 'SnapShop 用户', 'en': 'SnapShop User'},
    'personal_center': {'zh': '个人中心', 'en': 'Personal Center'},

    // History clear/delete dialogs
    'history_clear_title': {'zh': '清空搜索记录', 'en': 'Clear Search History'},
    'history_clear_message': {'zh': '确定要清空所有搜索记录吗？此操作不可恢复。', 'en': 'Clear all search history? This cannot be undone.'},
    'history_clear_confirm': {'zh': '清空', 'en': 'Clear'},
    'history_delete_title': {'zh': '删除记录', 'en': 'Delete Record'},
    'history_delete_message_image': {'zh': '确定要删除这条拍照识别记录吗？', 'en': 'Delete this photo recognition record?'},
    'history_delete_message_text': {'zh': '确定要删除这条搜索记录吗？', 'en': 'Delete this search record?'},
    'history_delete_confirm': {'zh': '删除', 'en': 'Delete'},
    'history_type_image': {'zh': '拍照', 'en': 'Photo'},
    'history_type_text': {'zh': '搜索', 'en': 'Search'},

    // Favorite dialog
    'favorite_need_login_title': {'zh': '需要登录', 'en': 'Login Required'},
    'favorite_need_login_content': {'zh': '收藏功能需要登录账号，是否前往登录？', 'en': 'Login is required to use favorites. Go to login?'},
    'go_to_login': {'zh': '去登录', 'en': 'Login'},
    'cancel': {'zh': '取消', 'en': 'Cancel'},
    'ok_label': {'zh': '确定', 'en': 'OK'},
    'favorite_failed': {'zh': '收藏操作失败，请重试', 'en': 'Favorite operation failed, please retry'},
    'favorite_failed_network': {'zh': '无法连接服务器，请检查网络', 'en': 'Cannot connect to server, check network'},
    'login_to_view_favorites': {'zh': '登录后可查看收藏', 'en': 'Log in to view favorites'},

    // Product detail
    'official_store': {'zh': '官方旗舰店', 'en': 'Official Store'},
    'third_party_store': {'zh': '第三方店铺', 'en': 'Third-party Store'},
    'rating': {'zh': '评分', 'en': 'Rating'},
    'product_tags': {'zh': '商品标签', 'en': 'Tags'},
    'product_attributes': {'zh': '商品属性', 'en': 'Attributes'},
    'go_to_platform': {'zh': '前往电商平台查看', 'en': 'View on Platform'},
    'mock_not_supported': {'zh': 'Mock数据不支持跳转到电商平台', 'en': 'Mock data does not support external links'},
    'link_open_failed': {'zh': '无法打开商品链接', 'en': 'Cannot open product link'},
    'sales_label': {'zh': '销量', 'en': 'Sales'},

    // Time formatting
    'x_minutes_ago': {'zh': '{}分钟前', 'en': '{}m ago'},
    'x_hours_ago': {'zh': '{}小时前', 'en': '{}h ago'},
    'x_days_ago': {'zh': '{}天前', 'en': '{}d ago'},
    'time_just_now': {'zh': '刚刚', 'en': 'Just now'},
    'history_deleted': {'zh': '已删除', 'en': 'Deleted'},
    'browse_delete_message': {'zh': '确定要删除这条浏览记录吗？', 'en': 'Delete this browsing record?'},
    'history_type_photo': {'zh': '拍照', 'en': 'Photo'},
    'history_type_search': {'zh': '搜索', 'en': 'Search'},
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
  String get noFavorites => get('no_favorites');
  String get noBrowseHistory => get('no_browse_history');
  String get browseClearTitle => get('browse_clear_title');
  String get browseClearMessage => get('browse_clear_message');
  String get browseDeleteItem => get('browse_delete_item');
  String get appearanceLight => get('appearance_light');
  String get appearanceDark => get('appearance_dark');
  String get appearanceSystem => get('appearance_system');
  String get fontSizeSmall => get('font_size_small');
  String get fontSizeStandard => get('font_size_standard');
  String get fontSizeLarge => get('font_size_large');
  String get fontSizePreview => get('font_size_preview');

  String get cacheClearTitle => get('cache_clear_title');
  String get cacheClearMessage => get('cache_clear_message');
  String get cacheConfirm => get('cache_confirm');
  String get cacheCancel => get('cache_cancel');
  String get cacheCleared => get('cache_cleared');

  String get notifPushTitle => get('notif_push_title');
  String get notifInappTitle => get('notif_inapp_title');

  String get profileEditTitle => get('profile_edit_title');
  String get profileNickname => get('profile_nickname');
  String get profileBio => get('profile_bio');
  String get profileBioHint => get('profile_bio_hint');
  String get profileSave => get('profile_save');
  String get profileSaveSuccess => get('profile_save_success');
  String get profileAvatarHint => get('profile_avatar_hint');

  String get loginTitle => get('login_title');
  String get loginPhoneHint => get('login_phone_hint');
  String get loginPasswordHint => get('login_password_hint');
  String get loginButton => get('login_button');
  String get loginNoAccount => get('login_no_account');
  String get loginRegister => get('login_register');
  String get registerTitle => get('register_title');
  String get registerButton => get('register_button');
  String get loginHaveAccount => get('login_have_account');
  String get loginBack => get('login_back');
  String get loginPhoneError => get('login_phone_error');
  String get loginSmsSentDebug => get('login_sms_sent_debug');
  String get loginSendSmsFailed => get('login_send_sms_failed');
  String get loginSmsCodeError => get('login_sms_code_error');
  String get loginPasswordTab => get('login_password_tab');
  String get loginSmsTab => get('login_sms_tab');
  String get loginSmsCodeHint => get('login_sms_code_hint');
  String get loginGetCode => get('login_get_code');
  String get loginSmsButton => get('login_sms_button');
  String get registerPasswordConfirmHint => get('register_password_confirm_hint');
  String get registerPasswordMismatch => get('register_password_mismatch');

  String get logoutTitle => get('logout_title');
  String get logoutMessage => get('logout_message');
  String get logoutConfirm => get('logout_confirm');
  String get logoutCancel => get('logout_cancel');

  // Error messages
  String get recognitionFailed => get('recognition_failed');
  String get searchFailed => get('search_failed');
  String get filterNoSession => get('filter_no_session');
  String get filterNetworkError => get('filter_network_error');
  String get filterEmptyResult => get('filter_empty_result');
  String get filterClearAll => get('filter_clear_all');
  String get loginFailed => get('login_failed');
  String get registerFailed => get('register_failed');
  String get noSearchHistory => get('no_search_history');
  String get historyLoginPrompt => get('history_login_prompt');
  String get historyLoginButton => get('history_login_button');
  String get snapshopUser => get('snapshop_user');
  String get personalCenter => get('personal_center');

  // Loading
  String get loadingTitle => get('loading_title');
  String get loadingSubtitle => get('loading_subtitle');

  // Error
  String get retry => get('retry');

  // History
  String get browseHistory => get('browse_history');
  String get searchHistory => get('search_history');
  String get historyTitle => get('history_title');
  String get historyClearTitle => get('history_clear_title');
  String get historyClearMessage => get('history_clear_message');
  String get historyClearConfirm => get('history_clear_confirm');
  String get historyDeleteTitle => get('history_delete_title');
  String get historyDeleteMessageImage => get('history_delete_message_image');
  String get historyDeleteMessageText => get('history_delete_message_text');
  String get historyDeleteConfirm => get('history_delete_confirm');
  String get historyTypeImage => get('history_type_image');
  String get historyTypeText => get('history_type_text');

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
  String get sortPriceDesc => get('sort_price_desc');
  String get sortSales => get('sort_sales');
  String get sortRating => get('sort_rating');

  // Price
  String get priceAllPlatforms => get('price_all_platforms');
  String get priceItemsFound => get('price_items_found');
  String get priceLowest => get('price_lowest');
  String get priceAverage => get('price_average');

  // Favorite dialog
  String get favoriteNeedLoginTitle => get('favorite_need_login_title');
  String get favoriteNeedLoginContent => get('favorite_need_login_content');
  String get goToLogin => get('go_to_login');
  String get cancel => get('cancel');
  String get okLabel => get('ok_label');
  String get favoriteFailed => get('favorite_failed');
  String get favoriteFailedNetwork => get('favorite_failed_network');

  // Product detail
  String get officialStore => get('official_store');
  String get thirdPartyStore => get('third_party_store');
  String get rating => get('rating');
  String get productTags => get('product_tags');
  String get productAttributes => get('product_attributes');
  String get goToPlatform => get('go_to_platform');
  String get mockNotSupported => get('mock_not_supported');
  String get linkOpenFailed => get('link_open_failed');
  String get salesLabel => get('sales_label');

  // Time formatting
  String get timeJustNow => get('time_just_now');
  String get loginToViewFavorites => get('login_to_view_favorites');
  String get historyDeleted => get('history_deleted');
  String get browseDeleteMessage => get('browse_delete_message');
  String get historyTypePhoto => get('history_type_photo');
  String get historyTypeSearch => get('history_type_search');

  String xMinutesAgo(int n) => get('x_minutes_ago').replaceFirst('{}', n.toString());
  String xHoursAgo(int n) => get('x_hours_ago').replaceFirst('{}', n.toString());
  String xDaysAgo(int n) => get('x_days_ago').replaceFirst('{}', n.toString());

  String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    final templateMin = get('x_minutes_ago');
    final templateHour = get('x_hours_ago');
    final templateDay = get('x_days_ago');
    if (diff.inMinutes < 1) {
      final isZh = locale.languageCode == 'zh';
      return isZh ? '刚刚' : 'Just now';
    }
    if (diff.inMinutes < 60) return templateMin.replaceFirst('{}', diff.inMinutes.toString());
    if (diff.inHours < 24) return templateHour.replaceFirst('{}', diff.inHours.toString());
    if (diff.inDays < 7) return templateDay.replaceFirst('{}', diff.inDays.toString());
    final isZh = locale.languageCode == 'zh';
    return isZh ? '${dt.month}/${dt.day}' : '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  String storeTypeLabel(String shopType) {
    return shopType == 'official' ? officialStore : thirdPartyStore;
  }
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
