import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/platform_badge.dart';
import '../../shared/widgets/optimized_cached_image.dart';
import '../settings/settings_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final MockProduct product;
  final VoidCallback onTap;
  final bool isFavorited;
  final VoidCallback? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isFavorited = false,
    this.onFavoriteChanged,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _favorited = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _favorited = widget.isFavorited;
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorited != widget.isFavorited) {
      _favorited = widget.isFavorited;
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
      widget.onFavoriteChanged?.call();
    } on DioException catch (e) {
      setState(() => _favorited = wasFavorited);
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
      setState(() => _favorited = wasFavorited);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.favoriteFailed}: $e'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: OptimizedCachedImage(
                    imageUrl: widget.product.imageUrl,
                    width: double.infinity,
                    memCacheWidth: 400,
                    memCacheHeight: 533,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: PlatformBadge(platform: widget.product.platform, isMock: widget.product.isMock),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Icon(
                        _favorited ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _favorited ? AppColors.priceRed : context.colors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.product.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: widget.product.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.priceRed.withAlpha(20),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: AppColors.priceRed.withAlpha(50)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: context.fs(9),
                              color: AppColors.priceRed,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\u00a5',
                              style: TextStyle(
                                fontSize: context.fs(11),
                                fontWeight: FontWeight.w700,
                                color: AppColors.priceRed,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                '${widget.product.price}',
                                style: TextStyle(
                                  fontSize: context.fs(20),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.priceRed,
                                  height: 1,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n.formatSalesCount(widget.product.salesCount),
                          style: TextStyle(
                            fontSize: context.fs(9),
                            color: context.colors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
