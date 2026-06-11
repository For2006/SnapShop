import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/browse_history_item.dart';
import '../../core/mock_data.dart';
import 'platform_badge.dart';
import 'optimized_cached_image.dart';

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
            return _buildTile(context, item, l10n);
          },
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, BrowseHistoryItem item, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onItemTap?.call(item.toMockProduct()),
        onLongPress: onDelete != null && item.id.isNotEmpty
            ? () => _showDeleteDialog(context, item, l10n)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              OptimizedCachedImage(
                imageUrl: item.imageUrl,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(8),
                memCacheWidth: 112,
                memCacheHeight: 112,
                placeholder: Container(color: context.colors.cardBg),
                errorWidget: Container(
                  color: context.colors.cardBg,
                  child: Icon(Icons.image, color: context.colors.textSecondary),
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
                            _formatTime(item.viewedAt!, l10n),
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

  void _showDeleteDialog(BuildContext context, BrowseHistoryItem item, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.browseDeleteItem),
        content: Text(l10n.browseDeleteMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cacheCancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await onDelete?.call(item);
              if (ok == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.historyDeleted), duration: const Duration(seconds: 1)),
                );
              }
            },
            child: Text(l10n.historyDeleteConfirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTime(String iso, AppLocalizations l10n) {
    try {
      return l10n.formatRelativeTime(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }
}
