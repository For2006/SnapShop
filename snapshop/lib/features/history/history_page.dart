import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/network/api_client.dart';
import '../../core/history_item.dart';
import '../../shared/widgets/search_history_section.dart';
import '../../shared/widgets/browse_history_section.dart';
import '../settings/settings_provider.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  final ApiClient _api = ApiClient();
  List<HistoryItem> _historyItems = [];
  List<BrowseHistoryItem> _browseItems = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final isLoggedIn = ref.read(settingsProvider).isLoggedIn;
    if (isLoggedIn) _loadAll();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isLoggedIn = ref.read(settingsProvider).isLoggedIn;
    if (isLoggedIn && _historyItems.isEmpty && _browseItems.isEmpty && !_loading) {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadHistory(), _loadBrowse()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadHistory() async {
    try {
      final response = await _api.get('/history');
      final data = response.data;
      List<HistoryItem> items = [];
      if (data is List) {
        items = data.map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
      } else if (data is Map && data['items'] is List) {
        items = (data['items'] as List).map((e) => HistoryItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      if (mounted) setState(() => _historyItems = items);
    } catch (e) {
      debugPrint('[HistoryPage] 加载搜索历史失败: $e');
    }
  }

  Future<void> _loadBrowse() async {
    try {
      final response = await _api.get('/browse', queryParameters: {'size': 30});
      final data = response.data;
      List<BrowseHistoryItem> items = [];
      if (data is Map && data['items'] is List) {
        items = (data['items'] as List)
            .map((e) => BrowseHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (mounted) setState(() => _browseItems = items);
    } catch (e) {
      debugPrint('[HistoryPage] 加载浏览历史失败: $e');
    }
  }

  Future<bool> _deleteSearchHistory(HistoryItem item) async {
    try {
      await _api.delete('/history/${item.sessionId}');
      setState(() => _historyItems.removeWhere((i) => i.sessionId == item.sessionId));
      return true;
    } catch (e) {
      debugPrint('[HistoryPage] 删除搜索历史失败: $e');
      return false;
    }
  }

  Future<bool> _deleteBrowseHistory(BrowseHistoryItem item) async {
    try {
      await _api.delete('/browse/${item.id}');
      setState(() => _browseItems.removeWhere((i) => i.id == item.id));
      return true;
    } catch (e) {
      debugPrint('[HistoryPage] 删除浏览历史失败: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: context.colors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: settingsState.isLoggedIn
                  ? _buildLoggedInHistory(context)
                  : _buildLoginPrompt(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).historyTitle,
            style: TextStyle(
              fontSize: context.fs(24),
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.close, size: 20, color: context.colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInHistory(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SearchHistorySection(
            historyItems: _historyItems,
            onHistoryItemTap: (item) => context.push('/results'),
            onDelete: _deleteSearchHistory,
          ),
          const SizedBox(height: 8),
          BrowseHistorySection(
            browseItems: _browseItems,
            onItemTap: (product) => context.push('/results'),
            onDelete: _deleteBrowseHistory,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: context.colors.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.historyLoginPrompt,
            style: TextStyle(
              fontSize: context.fs(14),
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text(
              l10n.historyLoginButton,
              style: TextStyle(
                fontSize: context.fs(14),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
