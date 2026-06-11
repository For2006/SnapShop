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
import '../../core/cache/api_cache.dart';
import 'settings_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
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
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              _buildHeader(context, l10n),
              _buildProfileCard(l10n, settingsState),
              _buildSection(
                icon: Icons.account_circle_outlined,
                title: l10n.settingsAccount,
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline,
                    label: l10n.settingsPersonalInfo,
                    subtitle: l10n.settingsPersonalInfoDesc,
                    onTap: () {
                      if (settingsState.isLoggedIn) {
                        _showProfileEditSheet(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先登录')),
                        );
                        context.push('/login');
                      }
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.shield_outlined,
                    label: l10n.settingsAccountSecurity,
                    subtitle: l10n.settingsAccountSecurityDesc,
                    onTap: () {
                      if (settingsState.isLoggedIn) {
                        context.push('/account-security');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请先登录')),
                        );
                        context.push('/login');
                      }
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    label: l10n.settingsNotifications,
                    subtitle: l10n.settingsNotificationsDesc,
                    onTap: () => _showNotificationPicker(context),
                  ),
                ],
              ),
              _buildSection(
                icon: Icons.tune_outlined,
                title: l10n.settingsPreferences,
                items: [
                  _SettingsItem(
                    icon: Icons.language,
                    label: l10n.settingsLanguage,
                    trailing: settingsState.localeOption.label,
                    onTap: () => _showLanguagePicker(context),
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    label: l10n.settingsAppearance,
                    trailing: settingsState.themeModeOption.label(l10n),
                    onTap: () => _showAppearancePicker(context),
                  ),
                  _SettingsItem(
                    icon: Icons.text_fields,
                    label: l10n.settingsFontSize,
                    trailing: settingsState.fontSizeOption.label(l10n),
                    onTap: () => _showFontSizePicker(context),
                  ),
                  _SettingsItem(
                    icon: Icons.cached_outlined,
                    label: l10n.settingsClearCache,
                    trailing: '0 KB',
                    onTap: () => _showClearCacheDialog(context),
                  ),
                ],
              ),
              _buildSection(
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
              const SizedBox(height: 16),
              if (settingsState.isLoggedIn)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        l10n.settingsLogout,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final currentLocale = ref.read(settingsProvider).localeOption;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
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
                  Navigator.pop(sheetCtx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.displayName,
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.brandBlue : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, size: 22, color: AppColors.brandBlue),
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

  void _showAppearancePicker(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final currentTheme = ref.read(settingsProvider).themeModeOption;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
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
                  Navigator.pop(sheetCtx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label(l10n),
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.brandBlue : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, size: 22, color: AppColors.brandBlue),
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

  void _showFontSizePicker(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final currentFontSize = ref.read(settingsProvider).fontSizeOption;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
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
                  Navigator.pop(sheetCtx);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.label(l10n),
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.brandBlue : context.colors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Aa',
                        style: TextStyle(
                          fontSize: 20 * option.scale,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? AppColors.brandBlue : context.colors.textSecondary,
                        ),
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.check_circle, size: 22, color: AppColors.brandBlue),
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

  void _showNotificationPicker(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final current = ref.read(settingsProvider);

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx2, setSheetState) {
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
                  title: Text(l10n.notifPushTitle, style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary)),
                  value: current.pushEnabled,
                  activeTrackColor: AppColors.brandBlue,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setPushEnabled(val);
                    setSheetState(() {});
                  },
                ),
                Divider(height: 0, indent: 16, endIndent: 16, color: context.colors.divider),
                SwitchListTile(
                  title: Text(l10n.notifInappTitle, style: TextStyle(fontSize: context.fs(15), color: context.colors.textPrimary)),
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

  void _showClearCacheDialog(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(l10n.cacheClearTitle),
        content: Text(l10n.cacheClearMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(l10n.cacheCancel)),
          TextButton(
            onPressed: () {
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              ApiCache().clear();
              Navigator.pop(dCtx);
              setState(() {});
            },
            child: Text(l10n.cacheConfirm, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brandBlue)),
          ),
        ],
      ),
    );
  }

  void _showProfileEditSheet(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx);
    final currentProfile = ref.read(settingsProvider);
    String? tempAvatarPath = currentProfile.avatarPath;
    final nameController = TextEditingController(text: currentProfile.nickname);
    final bioController = TextEditingController(text: currentProfile.bio);

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
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
                      style: TextStyle(fontSize: context.fs(17), fontWeight: FontWeight.w700, color: context.colors.textPrimary),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
                      if (picked != null) {
                        final dir = await getApplicationDocumentsDirectory();
                        final targetPath = '${dir.path}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        final compressed = await FlutterImageCompress.compressAndGetFile(picked.path, targetPath, quality: 85, minWidth: 512, minHeight: 512);
                        tempAvatarPath = compressed?.path ?? picked.path;
                        setSheetState(() {});
                      }
                    },
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.cardBg, border: Border.all(color: context.colors.divider, width: 1)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (tempAvatarPath != null)
                            ClipOval(child: Image.file(File(tempAvatarPath!), width: 88, height: 88, fit: BoxFit.cover))
                          else
                            Icon(Icons.person, size: 40, color: context.colors.textTertiary),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.brandBlue),
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
                        filled: true,
                        fillColor: context.colors.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
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
                        filled: true,
                        fillColor: context.colors.cardBg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () async {
                          final nickname = nameController.text.trim().isEmpty
                              ? 'SnapShop 用户'
                              : nameController.text.trim();
                          final bio = bioController.text.trim();
                          try {
                            Navigator.pop(ctx2);
                          } catch (_) {}
                          final error = await ref.read(settingsProvider.notifier).setProfile(
                            tempAvatarPath, nickname, bio,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(error ?? l10n.profileSaveSuccess),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(backgroundColor: AppColors.brandBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text(l10n.profileSave, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
              decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
              child: Icon(Icons.chevron_left, size: 20, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              l10n.settingsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.fs(18), fontWeight: FontWeight.w700, color: context.colors.textPrimary, letterSpacing: -0.3),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(shape: BoxShape.circle, color: context.colors.cardBg),
                child: settingsState.avatarPath != null
                    ? ClipOval(child: Image.file(File(settingsState.avatarPath!), width: 56, height: 56, fit: BoxFit.cover))
                    : const Icon(Icons.person, size: 28, color: Colors.white70),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(settingsState.nickname, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: context.colors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(settingsState.bio.isNotEmpty ? settingsState.bio : '这个人很懒，什么都没写~', style: TextStyle(fontSize: 13, color: context.colors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
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
                  decoration: BoxDecoration(color: AppColors.brandBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 15, color: AppColors.brandBlue),
                ),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: context.colors.textPrimary, letterSpacing: -0.2)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(16)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Container(width: 34, height: 34, decoration: BoxDecoration(color: _iconBgColor(item), borderRadius: BorderRadius.circular(10)), child: Icon(item.icon, size: 17, color: _iconColor(item))),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.label, style: TextStyle(fontSize: context.fs(14), fontWeight: FontWeight.w500, color: context.colors.textPrimary)),
                                  if (item.subtitle != null)
                                    Padding(padding: const EdgeInsets.only(top: 2), child: Text(item.subtitle!, style: TextStyle(fontSize: context.fs(11), color: context.colors.textTertiary))),
                                ],
                              ),
                            ),
                            if (item.trailing != null) Text(item.trailing!, style: TextStyle(fontSize: context.fs(13), color: context.colors.textTertiary)),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right, size: 16, color: context.colors.textTertiary.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    if (!isLast)
                      Padding(padding: const EdgeInsets.only(left: 60), child: Divider(height: 0, thickness: 0.5, color: context.colors.cardBg)),
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
