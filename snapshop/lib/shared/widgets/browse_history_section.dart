import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';
import 'platform_badge.dart';

class BrowseHistoryItem {
  final String id;
  final String productId;
  final String name;
  final double price;
  final String platform;
  final String imageUrl;
  final String? shopName;
  final String? viewedAt;
  final bool isMock;

  const BrowseHistoryItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.price,
    required this.platform,
    required this.imageUrl,
    this.shopName,
    this.viewedAt,
    this.isMock = false,
  });

  factory BrowseHistoryItem.fromJson(Map<String, dynamic> json) {
    final snap = json['product_snapshot'] as Map<String, dynamic>? ?? json;
    return BrowseHistoryItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      name: snap['name']?.toString() ?? '',
      price: double.tryParse(snap['price']?.toString() ?? '0') ?? 0,
      platform: snap['platform']?.toString() ?? '',
      imageUrl: snap['image_url']?.toString() ?? '',
      shopName: snap['shop_name']?.toString(),
      viewedAt: json['viewed_at']?.toString(),
      isMock: snap['is_mock'] == true,
    );
  }

  MockProduct toMockProduct() {
    return MockProduct(
      id: productId,
      name: name,
      price: price,
      originalPrice: price,
      platform: platform,
      imageUrl: imageUrl,
      shopName: shopName ?? '',
      shopType: 'third_party',
      rating: 0,
      salesCount: 0,
      productUrl: '',
      isMock: isMock,
      tags: const [],
    );
  }
}

class BrowseHistorySection extends StatelessWidget {
  final List<MockProduct> products;
  final List<BrowseHistoryItem> browseItems;
  final void Function(MockProduct product)? onItemTap;
  final Future<bool> Function(BrowseHistoryItem item)? onDelete;

  const BrowseHistorySection({
    super.key,
    this.products = const [],
    this.browseItems = const [],
    this.onItemTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final hasOldData = products.isNotEmpty;
    final displayItems = browseItems.isNotEmpty
        ? browseItems
        : products.map((p) => BrowseHistoryItem(
              id: '',
              productId: p.id,
              name: p.name,
              price: p.price,
              platform: p.platform,
              imageUrl: p.imageUrl,
            )).toList();

    if (displayItems.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            l10n.noBrowseHistory,
            style: TextStyle(color: context.colors.textSecondary, fontSize: context.fs(14)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.browseHistory,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayItems.length,
          separatorBuilder: (_, __) => Divider(height: 1, indent: 72, color: context.colors.divider),
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return _buildTile(context, item, hasOldData);
          },
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, BrowseHistoryItem item, bool useLegacyTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemTap?.call(item.toMockProduct()),
        onLongPress: onDelete != null && item.id.isNotEmpty
            ? () => _showDeleteDialog(context, item)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: context.colors.cardBg),
                    errorWidget: (_, __, ___) => Container(
                      color: context.colors.cardBg,
                      child: Icon(Icons.image, color: context.colors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PlatformBadge(platform: item.platform, isMock: item.isMock),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: context.fs(14),
                              fontWeight: FontWeight.w500,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '¥${item.price}',
                          style: TextStyle(
                            fontSize: context.fs(15),
                            fontWeight: FontWeight.w700,
                            color: AppColors.priceRed,
                          ),
                        ),
                        if (item.viewedAt != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(item.viewedAt!),
                            style: TextStyle(fontSize: context.fs(11), color: context.colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: context.colors.textSecondary.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BrowseHistoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除浏览记录'),
        content: const Text('确定要删除这条浏览记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await onDelete?.call(item);
              if (ok == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已删除'), duration: Duration(seconds: 1)),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
      if (diff.inHours < 24) return '${diff.inHours}小时前';
      if (diff.inDays < 7) return '${diff.inDays}天前';
      return '${dt.month}/${dt.day}';
    } catch (_) {
      return '';
    }
  }
}
