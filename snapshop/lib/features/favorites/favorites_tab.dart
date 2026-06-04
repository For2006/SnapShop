import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../config/theme_context.dart';
import '../../config/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/platform_badge.dart';
import '../settings/settings_provider.dart';

class FavoritesTab extends ConsumerStatefulWidget {
  const FavoritesTab({super.key});

  @override
  ConsumerState<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends ConsumerState<FavoritesTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isLoggedIn = ref.read(settingsProvider).isLoggedIn;
    if (!isLoggedIn) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ApiClient();
      final response = await api.get('/favorites', queryParameters: {'page': 1, 'size': 50});
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        debugPrint('[FavoritesTab] 响应格式异常: ${raw.runtimeType}');
        if (mounted) setState(() => _loading = false);
        return;
      }
      final data = raw;
      final list = data['items'];
      final items = list is List ? list.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
      if (mounted) setState(() { _items = items; _loading = false; });
    } on DioException catch (e) {
      debugPrint('[FavoritesTab] _load Dio错误: $e');
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('[FavoritesTab] _load 失败: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(String productId) async {
    try {
      final api = ApiClient();
      await api.delete('/favorites/$productId');
      _load();
    } catch (e) {
      debugPrint('[FavoritesTab] _removeFavorite 失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(settingsProvider).isLoggedIn;

    if (!isLoggedIn) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 48, color: context.colors.textTertiary),
            const SizedBox(height: 12),
            Text('登录后可查看收藏', style: TextStyle(fontSize: context.fs(14), color: context.colors.textTertiary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.priceRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('去登录'),
            ),
          ],
        ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 48, color: context.colors.textTertiary),
            const SizedBox(height: 12),
            Text(
              '暂无收藏',
              style: TextStyle(fontSize: context.fs(14), color: context.colors.textTertiary),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final snapshot = (item['product_snapshot'] ?? {}) as Map<String, dynamic>;

        return Container(
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
                      errorWidget: (_, __, ___) => Container(color: context.colors.cardBg),
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
                          style: TextStyle(fontSize: context.fs(11), color: context.colors.textPrimary, height: 1.3),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text('\u00a5', style: TextStyle(fontSize: context.fs(10), fontWeight: FontWeight.w700, color: AppColors.priceRed)),
                            Text('${snapshot['price'] ?? 0}', style: TextStyle(fontSize: context.fs(15), fontWeight: FontWeight.w700, color: AppColors.priceRed, height: 1)),
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
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _removeFavorite(item['product_id']?.toString() ?? ''),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: const Icon(Icons.favorite, size: 16, color: AppColors.priceRed),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
