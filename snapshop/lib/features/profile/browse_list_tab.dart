import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../config/theme_context.dart';
import '../../config/app_colors.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/platform_badge.dart';

class BrowseListTab extends ConsumerStatefulWidget {
  const BrowseListTab({super.key});

  @override
  ConsumerState<BrowseListTab> createState() => _BrowseListTabState();
}

class _BrowseListTabState extends ConsumerState<BrowseListTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  late final AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final response = await api.get('/browse', queryParameters: {'page': 1, 'size': 50});
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final list = raw['items'];
      final items = list is List ? list.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      debugPrint('[BrowseListTab] _load 失败: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteSingle(int index) async {
    final item = _items[index];
    final browseId = item['id']?.toString() ?? '';
    final removed = _items.removeAt(index);
    setState(() {});

    try {
      final api = ApiClient();
      await api.delete('/browse/$browseId');
    } catch (e) {
      debugPrint('[BrowseListTab] 删除失败: $e');
      if (mounted) {
        _items.insert(index.clamp(0, _items.length), removed);
        setState(() {});
      }
    }
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.browseClearTitle),
        content: Text(_l10n.browseClearMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_l10n.cacheCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(_l10n.logoutConfirm),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final backup = List<Map<String, dynamic>>.from(_items);
      setState(() => _items = []);
      try {
        final api = ApiClient();
        await api.delete('/browse');
      } catch (e) {
        debugPrint('[BrowseListTab] 清空失败: $e');
        if (mounted) setState(() => _items = backup);
      }
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return '刚刚';
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return DateFormat('M/d').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 48, color: context.colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              _l10n.noBrowseHistory,
              style: TextStyle(fontSize: context.fs(14), color: context.colors.textTertiary),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _l10n.browseHistory,
                  style: TextStyle(
                    fontSize: context.fs(15),
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: _clearAll,
                  child: Text(
                    _l10n.browseClearTitle,
                    style: TextStyle(
                      fontSize: context.fs(13),
                      color: Colors.red.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.57,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final snapshot = (item['product_snapshot'] ?? {}) as Map<String, dynamic>;
                final viewedAt = item['viewed_at']?.toString();

                return GestureDetector(
                  onTap: () {
                    final product = MockProduct.fromJson(snapshot);
                    context.push('/product-detail', extra: product);
                  },
                  onLongPress: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36,
                              height: 4,
                              margin: const EdgeInsets.only(top: 12, bottom: 8),
                              decoration: BoxDecoration(
                                color: context.colors.divider,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.delete_outline, color: Colors.red),
                              title: Text(
                                _l10n.browseDeleteItem,
                                style: const TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.of(ctx).pop();
                                _deleteSingle(index);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.colors.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 3 / 4,
                              child: CachedNetworkImage(
                                imageUrl: snapshot['image_url']?.toString() ?? '',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                placeholder: (_, __) => Container(color: context.colors.cardBg),
                                errorWidget: (_, __, ___) => Container(
                                  color: context.colors.cardBg,
                                  child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot['name']?.toString() ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: context.fs(11),
                                      color: context.colors.textPrimary,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '¥',
                                            style: TextStyle(
                                              fontSize: context.fs(10),
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.priceRed,
                                            ),
                                          ),
                                          Text(
                                            '${snapshot['price'] ?? 0}',
                                            style: TextStyle(
                                              fontSize: context.fs(15),
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.priceRed,
                                              height: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        _formatTime(viewedAt),
                                        style: TextStyle(
                                          fontSize: context.fs(9),
                                          color: context.colors.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: PlatformBadge(platform: snapshot['platform']?.toString() ?? '', isMock: snapshot['is_mock'] == true),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
