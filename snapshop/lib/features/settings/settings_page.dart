import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/app_colors.dart';
import '../../config/l10n/app_localizations.dart';
import '../../config/theme_context.dart';
import 'settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _profileAnim;
  late final Animation<double> _sectionsAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _profileAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
    );
    _sectionsAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showLanguagePicker() {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.read(settingsProvider).localeOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(bottom: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.settingsLanguage,
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            ...LocaleOption.values.map((option) {
              final isSelected = option == currentLocale;
              return InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).setLocale(option);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.displayName,
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.brandBlue
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          size: 22,
                          color: AppColors.brandBlue,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showAppearancePicker() {
    final l10n = AppLocalizations.of(context);
    final currentTheme = ref.read(settingsProvider).themeModeOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(bottom: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.settingsAppearance,
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            ...ThemeModeOption.values.map((option) {
              final isSelected = option == currentTheme;
              return InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).setThemeMode(option);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label(l10n),
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.brandBlue
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          size: 22,
                          color: AppColors.brandBlue,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showFontSizePicker() {
    final l10n = AppLocalizations.of(context);
    final currentFontSize = ref.read(settingsProvider).fontSizeOption;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(bottom: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                l10n.settingsFontSize,
                style: TextStyle(
                  fontSize: context.fs(17),
                  fontWeight: FontWeight.w700,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
            ...FontSizeOption.values.map((option) {
              final isSelected = option == currentFontSize;
              return InkWell(
                onTap: () {
                  ref.read(settingsProvider.notifier).setFontSize(option);
                  Navigator.pop(ctx);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label(l10n),
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.brandBlue
                                : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 20 * option.scale,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? AppColors.brandBlue
                              : context.colors.textSecondary,
                        ),
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.check_circle,
                            size: 22,
                            color: AppColors.brandBlue,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showNotificationPicker() {
    final l10n = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) {
          final current = ref.read(settingsProvider);
          return Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.only(bottom: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    l10n.settingsNotifications,
                    style: TextStyle(
                      fontSize: context.fs(17),
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                ),
                SwitchListTile(
                  title: Text(
                    l10n.notifPushTitle,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      color: context.colors.textPrimary,
                    ),
                  ),
                  value: current.pushEnabled,
                  activeTrackColor: AppColors.brandBlue,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setPushEnabled(val);
                    setSheetState(() {});
                  },
                ),
                Divider(height: 0, indent: 16, endIndent: 16, color: context.colors.divider),
                SwitchListTile(
                  title: Text(
                    l10n.notifInappTitle,
                    style: TextStyle(
                      fontSize: context.fs(15),
                      color: context.colors.textPrimary,
                    ),
                  ),
                  value: current.inAppAlertsEnabled,
                  activeTrackColor: AppColors.brandBlue,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setInAppAlertsEnabled(val);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getCacheSize() {
    final cache = PaintingBinding.instance.imageCache;
    final bytes = cache.currentSizeBytes;
    if (bytes < 1024) return '0 KB';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showClearCacheDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cacheClearTitle),
        content: Text(l10n.cacheClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cacheCancel),
          ),
          TextButton(
            onPressed: () {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              Navigator.pop(ctx);
              setState(() {});
            },
            child: Text(
              l10n.cacheConfirm,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileEditSheet() {
    final l10n = AppLocalizations.of(context);
    final currentProfile = ref.read(settingsProvider);

    String? tempAvatarPath = currentProfile.avatarPath;
    final nameController = TextEditingController(text: currentProfile.nickname);
    final bioController = TextEditingController(text: currentProfile.bio);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.only(bottom: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.textTertiary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Text(
                      l10n.profileEditTitle,
                      style: TextStyle(
                        fontSize: context.fs(17),
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
                      if (picked != null) {
                        final dir = await getApplicationDocumentsDirectory();
                        final targetPath = '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final compressed = await FlutterImageCompress.compressAndGetFile(
                          picked.path, targetPath,
                          quality: 85,
                          minWidth: 512,
                          minHeight: 512,
                        );
                        tempAvatarPath = compressed?.path ?? picked.path;
                        setSheetState(() {});
                      }
                    },
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.cardBg,
                        border: Border.all(color: context.colors.divider, width: 1),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (tempAvatarPath != null)
                            ClipOval(
                              child: Image.file(
                                File(tempAvatarPath!),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Icon(Icons.person, size: 40, color: context.colors.textTertiary),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.brandBlue,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: l10n.profileNickname,
                        labelStyle: TextStyle(color: context.colors.textSecondary, fontSize: context.fs(14)),
                        filled: true,
                        fillColor: context.colors.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: bioController,
                      maxLines: 3,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: l10n.profileBio,
                        hintText: l10n.profileBioHint,
                        labelStyle: TextStyle(color: context.colors.textSecondary, fontSize: context.fs(14)),
                        hintStyle: TextStyle(color: context.colors.textTertiary, fontSize: context.fs(14)),
                        filled: true,
                        fillColor: context.colors.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                      style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          ref.read(settingsProvider.notifier).setProfile(
                            tempAvatarPath,
                            nameController.text.trim().isEmpty ? 'SnapShop 用户' : nameController.text.trim(),
                            bioController.text.trim(),
                          );
                          Navigator.pop(ctx2);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          l10n.profileSave,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      nameController.dispose();
      bioController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsState = ref.watch(settingsProvider);

    final brightness = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: brightness == Brightness.dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.colors.secondaryBg,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -120,
                left: -80,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandBlue.withValues(alpha: 0.08),
                        AppColors.brandPurple.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -40,
                right: -100,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.brandPurple.withValues(alpha: 0.06),
                        AppColors.brandBlue.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  _buildHeader(context, l10n),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        _AnimatedSlide(
                          animation: _profileAnim,
                          child: _buildProfileCard(l10n, settingsState),
                        ),
                        _AnimatedSlide(
                          animation: _sectionsAnim,
                          child: _buildSection(
                            icon: Icons.account_circle_outlined,
                            title: l10n.settingsAccount,
                            items: [
                              _SettingsItem(
                                icon: Icons.person_outline,
                                label: l10n.settingsPersonalInfo,
                                subtitle: l10n.settingsPersonalInfoDesc,
                                onTap: () {},
                              ),
                              _SettingsItem(
                                icon: Icons.shield_outlined,
                                label: l10n.settingsAccountSecurity,
                                subtitle: l10n.settingsAccountSecurityDesc,
                                onTap: () {},
                              ),
                              _SettingsItem(
                                icon: Icons.notifications_outlined,
                                label: l10n.settingsNotifications,
                                subtitle: l10n.settingsNotificationsDesc,
                                onTap: _showNotificationPicker,
                              ),
                            ],
                          ),
                        ),
                        _AnimatedSlide(
                          animation: _sectionsAnim,
                          child: _buildSection(
                            icon: Icons.tune_outlined,
                            title: l10n.settingsPreferences,
                            items: [
                              _SettingsItem(
                                icon: Icons.language,
                                label: l10n.settingsLanguage,
                                trailing: settingsState.localeOption.label,
                                onTap: _showLanguagePicker,
                              ),
                              _SettingsItem(
                                icon: Icons.palette_outlined,
                                label: l10n.settingsAppearance,
                                trailing: settingsState.themeModeOption.label(l10n),
                                onTap: _showAppearancePicker,
                              ),
                              _SettingsItem(
                                icon: Icons.text_fields,
                                label: l10n.settingsFontSize,
                                trailing: settingsState.fontSizeOption.label(l10n),
                                onTap: _showFontSizePicker,
                              ),
                              _SettingsItem(
                                icon: Icons.cached_outlined,
                                label: l10n.settingsClearCache,
                                trailing: _getCacheSize(),
                                onTap: _showClearCacheDialog,
                              ),
                            ],
                          ),
                        ),
                        _AnimatedSlide(
                          animation: _sectionsAnim,
                          child: _buildSection(
                            icon: Icons.info_outline,
                            title: l10n.settingsAbout,
                            items: [
                              _SettingsItem(
                                icon: Icons.system_update_outlined,
                                label: l10n.settingsCheckUpdate,
                                trailing: 'v1.0.0',
                                onTap: () {},
                              ),
                              _SettingsItem(
                                icon: Icons.description_outlined,
                                label: l10n.settingsUserAgreement,
                                onTap: () {},
                              ),
                              _SettingsItem(
                                icon: Icons.privacy_tip_outlined,
                                label: l10n.settingsPrivacyPolicy,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (settingsState.isLoggedIn)
                          _AnimatedSlide(
                            animation: _sectionsAnim,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(l10n.logoutTitle),
                                        content: Text(l10n.logoutMessage),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: Text(l10n.logoutCancel),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              ref.read(settingsProvider.notifier).logout();
                                              Navigator.pop(ctx);
                                            },
                                            child: Text(
                                              l10n.logoutConfirm,
                                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.errorRed),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.errorRed,
                                    side: BorderSide(
                                        color: AppColors.errorRed
                                            .withValues(alpha: 0.3)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    l10n.settingsLogout,
                                    style: TextStyle(
                                      fontSize: context.fs(15),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.chevron_left,
                  size: 20, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              l10n.settingsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: context.fs(18),
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AppLocalizations l10n, SettingsState settingsState) {
    return GestureDetector(
      onTap: () {
        if (settingsState.isLoggedIn) {
          context.push('/profile');
        } else {
          context.push('/login');
        }
      },
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF2D1B69)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D1B69).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: 40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: settingsState.avatarPath != null
                      ? ClipOval(
                          child: Image.file(
                            File(settingsState.avatarPath!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.person, size: 32, color: Colors.white70),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settingsState.nickname,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settingsState.bio.isNotEmpty ? settingsState.bio : 'user@example.com',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      if (settingsState.isLoggedIn) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _profileStat('${settingsState.favoriteCount}', l10n.settingsFavorites),
                            _profileDivider(),
                            _profileStat('${settingsState.browseCount}', l10n.settingsFootprints),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _profileStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.55))),
      ],
    );
  }

  Widget _profileDivider() {
    return Container(width: 1, height: 24, margin: const EdgeInsets.symmetric(horizontal: 16), color: Colors.white.withValues(alpha: 0.12));
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10, top: 8),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.brandBlue),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: items.asMap().entries.map((entry) {
                final isLast = entry.key == items.length - 1;
                final item = entry.value;
                return Column(
                  children: [
                    InkWell(
                      onTap: item.onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _iconBgColor(item),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                size: 17,
                                color: _iconColor(item),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: context.fs(14),
                                      fontWeight: FontWeight.w500,
                                      color: context.colors.textPrimary,
                                    ),
                                  ),
                                  if (item.subtitle != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.subtitle!,
                                        style: TextStyle(
                                          fontSize: context.fs(11),
                                          color: context.colors.textTertiary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (item.trailing != null)
                              Text(
                                item.trailing!,
                                style: TextStyle(
                                  fontSize: context.fs(13),
                                  color: context.colors.textTertiary,
                                ),
                              ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color:
                                  context.colors.textTertiary.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.only(left: 60),
                        child: Divider(
                            height: 0,
                            thickness: 0.5,
                            color: context.colors.cardBg),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _iconColor(_SettingsItem item) {
    if (item.iconColor != null) return item.iconColor!;
    return context.colors.textSecondary;
  }

  Color _iconBgColor(_SettingsItem item) {
    if (item.iconColor != null) return item.iconColor!.withValues(alpha: 0.1);
    return context.colors.cardBg;
  }
}

class _AnimatedSlide extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _AnimatedSlide({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 32 * (1.0 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.iconColor,
  });
}
