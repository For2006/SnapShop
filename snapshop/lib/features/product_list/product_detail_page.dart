import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/platform_badge.dart';
import '../../shared/widgets/optimized_cached_image.dart';
import '../settings/settings_provider.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final MockProduct product;
  final bool? initialIsFavorited;

  const ProductDetailPage({
    super.key,
    required this.product,
    this.initialIsFavorited,
  });

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late bool _favorited;
  bool _toggling = false;
  bool _browseRecorded = false;

  @override
  void initState() {
    super.initState();
    _favorited = widget.initialIsFavorited ?? false;
    _recordBrowse();
    if (widget.initialIsFavorited == null) {
      _checkFavoriteStatus();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final api = ApiClient();
      final token = ApiClient.accessToken;
      if (token == null || token.isEmpty) return;
      final response = await api.get('/favorites/${widget.product.id}');
      if (mounted) {
        setState(() => _favorited = true);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && mounted) {
        setState(() => _favorited = false);
      }
    } catch (_) {
    }
  }

  Future<void> _recordBrowse() async {
    if (_browseRecorded) return;
    try {
      final api = ApiClient();
      await api.post('/browse', data: {
        'product_id': widget.product.id,
        'product_snapshot': {
          'id': widget.product.id,
          'name': widget.product.name,
          'price': widget.product.price,
          'original_price': widget.product.originalPrice,
          'platform': widget.product.platform,
          'image_url': widget.product.imageUrl,
          'shop_name': widget.product.shopName,
          'shop_type': widget.product.shopType,
          'rating': widget.product.rating,
          'sales_count': widget.product.salesCount,
          'is_mock': widget.product.isMock,
          'tags': widget.product.tags,
        },
      });
      _browseRecorded = true;
      if (mounted) {
        ref.read(settingsProvider.notifier).refreshStats();
      }
    } catch (e) {
      debugPrint('[ProductDetailPage] 记录浏览足迹失败: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_toggling) return;

    final l10n = AppLocalizations.of(context);
    final isLoggedIn = ref.read(settingsProvider).isLoggedIn;
    if (!isLoggedIn) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.favoriteNeedLoginTitle),
          content: Text(l10n.favoriteNeedLoginContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.goToLogin),
            ),
          ],
        ),
      );
      if (go == true && mounted) {
        context.push('/login');
      }
      return;
    }

    final wasFavorited = _favorited;
    setState(() { _favorited = !_favorited; _toggling = true; });

    try {
      final api = ApiClient();
      if (wasFavorited) {
        await api.delete('/favorites/${widget.product.id}');
      } else {
        await api.post('/favorites', data: {
          'product_id': widget.product.id,
          'product_snapshot': {
            'id': widget.product.id,
            'name': widget.product.name,
            'price': widget.product.price,
            'original_price': widget.product.originalPrice,
            'platform': widget.product.platform,
            'image_url': widget.product.imageUrl,
            'shop_name': widget.product.shopName,
            'shop_type': widget.product.shopType,
            'rating': widget.product.rating,
            'sales_count': widget.product.salesCount,
            'is_mock': widget.product.isMock,
            'tags': widget.product.tags,
          },
        });
      }
      if (mounted) {
        ref.read(settingsProvider.notifier).refreshStats();
      }
    } on DioException catch (e) {
      if (mounted) setState(() => _favorited = wasFavorited);
      if (mounted) {
        String message = l10n.favoriteFailed;
        if (e.response != null) {
          final detail = e.response!.data;
          if (detail is Map<String, dynamic>) {
            message = detail['message']?.toString() ?? message;
          }
        } else if (e.type == DioExceptionType.connectionError) {
          message = l10n.favoriteFailedNetwork;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _favorited = wasFavorited);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.favoriteFailed}: $e'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _openExternalLink() async {
    final l10n = AppLocalizations.of(context);
    if (widget.product.isMock) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.mockNotSupported), duration: const Duration(seconds: 2)),
        );
      }
      return;
    }
    final url = widget.product.productUrl;
    if (url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkOpenFailed), duration: const Duration(seconds: 2)),
        );
      }
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkOpenFailed), duration: const Duration(seconds: 2)),
        );
      }
      return;
    }
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkOpenFailed), duration: const Duration(seconds: 2)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.linkOpenFailed), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: context.colors.primaryBg,
        body: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: context.colors.textPrimary),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    OptimizedCachedImage(
                      imageUrl: widget.product.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      memCacheHeight: 600,
                      fadeInDuration: const Duration(milliseconds: 100),
                      errorWidget: Container(
                        color: context.colors.cardBg,
                        child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 64)),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: PlatformBadge(platform: widget.product.platform, isMock: widget.product.isMock),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontSize: context.fs(18),
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '\u00a5',
                          style: TextStyle(
                            fontSize: context.fs(16),
                            fontWeight: FontWeight.w700,
                            color: AppColors.priceRed,
                          ),
                        ),
                        Text(
                          '${widget.product.price}',
                          style: TextStyle(
                            fontSize: context.fs(32),
                            fontWeight: FontWeight.w700,
                            color: AppColors.priceRed,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '¥${widget.product.originalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: context.fs(14),
                            color: context.colors.textTertiary,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.colors.border),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.storefront_outlined, size: 18, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.product.shopName,
                                  style: TextStyle(
                                    fontSize: context.fs(14),
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withAlpha(26),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.storeTypeLabel(widget.product.shopType),
                                  style: TextStyle(
                                    fontSize: context.fs(11),
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(height: 1, color: context.colors.border),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.product.rating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: context.fs(14),
                                            fontWeight: FontWeight.w600,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.rating,
                                      style: TextStyle(
                                        fontSize: context.fs(11),
                                        color: context.colors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: context.colors.border,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      l10n.formatSalesCount(widget.product.salesCount),
                                      style: TextStyle(
                                        fontSize: context.fs(14),
                                        fontWeight: FontWeight.w600,
                                        color: context.colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.salesLabel,
                                      style: TextStyle(
                                        fontSize: context.fs(11),
                                        color: context.colors.textTertiary,
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
                    const SizedBox(height: 20),
                    if (widget.product.tags.isNotEmpty) ...[
                      Text(
                        l10n.productTags,
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.product.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.priceRed.withAlpha(20),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.priceRed.withAlpha(50)),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: context.fs(12),
                                color: AppColors.priceRed,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (widget.product.attributes.isNotEmpty) ...[
                      Text(
                        l10n.productAttributes,
                        style: TextStyle(
                          fontSize: context.fs(15),
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: context.colors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: widget.product.attributes.length,
                          separatorBuilder: (context, index) => Divider(height: 1, color: context.colors.border, indent: 16),
                          itemBuilder: (context, index) {
                            final entry = widget.product.attributes.entries.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    entry.key.toString(),
                                    style: TextStyle(
                                      fontSize: context.fs(14),
                                      color: context.colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        fontSize: context.fs(14),
                                        color: context.colors.textPrimary,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _toggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _favorited
                        ? AppColors.priceRed.withValues(alpha: 0.1)
                        : context.colors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _favorited ? AppColors.priceRed : context.colors.border,
                    ),
                  ),
                  child: Icon(
                    _favorited ? Icons.favorite : Icons.favorite_border,
                    color: _favorited ? AppColors.priceRed : context.colors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _openExternalLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.priceRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.open_in_new, size: 20),
                    label: Text(
                      l10n.goToPlatform,
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w600,
                      ),
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
}
