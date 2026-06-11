import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../settings/settings_provider.dart';
import '../favorites/favorites_tab.dart';
import 'browse_list_tab.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).refreshStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settingsState = ref.watch(settingsProvider);
    final (favoriteCount, browseCount) = ref.watch(statsProvider);

    return Scaffold(
      backgroundColor: context.colors.secondaryBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, l10n),
            _buildUserCard(context, l10n, settingsState),
            TabBar(
              controller: _tabController,
              labelColor: context.colors.textPrimary,
              unselectedLabelColor: context.colors.textTertiary,
              indicatorColor: context.colors.textPrimary,
              tabs: [
                Tab(text: '${l10n.settingsFavorites} ($favoriteCount)'),
                Tab(text: '${l10n.settingsFootprints} ($browseCount)'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FavoritesTab(),
                  BrowseListTab(),
                ],
              ),
            ),
          ],
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
              child: Icon(Icons.chevron_left, size: 20, color: context.colors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              l10n.personalCenter,
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

  Widget _buildUserCard(BuildContext context, AppLocalizations l10n, SettingsState settings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2D1B69),
              ),
              child: const Icon(Icons.person, size: 24, color: Colors.white70),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.nickname,
                    style: TextStyle(
                      fontSize: context.fs(16),
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.bio.isNotEmpty ? settings.bio : '这个人很懒，什么都没写~',
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
