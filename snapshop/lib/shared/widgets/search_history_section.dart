import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/history_item.dart';

class SearchHistorySection extends StatelessWidget {
  final List<String> items;
  final void Function(String item)? onItemTap;
  final List<HistoryItem> historyItems;
  final void Function(HistoryItem item)? onHistoryItemTap;
  final Future<bool> Function(HistoryItem item)? onDelete;
  final VoidCallback? onClearAll;

  const SearchHistorySection({
    super.key,
    this.items = const [],
    this.onItemTap,
    this.historyItems = const [],
    this.onHistoryItemTap,
    this.onDelete,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final displayItems = historyItems.isNotEmpty
        ? historyItems
        : items.map((s) => HistoryItem(sessionId: '', searchQuery: s, searchType: 'text')).toList();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l10n.searchHistory,
            style: TextStyle(
              fontSize: context.fs(13),
              fontWeight: FontWeight.w600,
              color: context.colors.textSecondary,
            ),
          ),
          if (onClearAll != null)
            GestureDetector(
              onTap: () => _showClearAllDialog(context),
              child: Text(
                '清空',
                style: TextStyle(
                  fontSize: context.fs(12),
                  color: Colors.red.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );

    if (displayItems.isEmpty) {
      return ListView(
        children: [
          header,
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.noSearchHistory,
                style: TextStyle(color: context.colors.textSecondary, fontSize: context.fs(14)),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      children: [
        header,
        for (int i = 0; i < displayItems.length; i++) ...[
          _buildTile(context, displayItems[i], displayItems[i].searchType == 'image'),
          if (i < displayItems.length - 1)
            Divider(height: 1, indent: 56, color: context.colors.divider),
        ],
      ],
    );
  }

  Widget _buildTile(BuildContext context, HistoryItem item, bool isImage) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (historyItems.isNotEmpty) {
            onHistoryItemTap?.call(item);
          } else {
            onItemTap?.call(item.searchQuery ?? '');
          }
        },
        onLongPress: onDelete != null ? () => _showDeleteDialog(context, item) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isImage
                      ? AppColors.brandBlue.withOpacity(0.1)
                      : context.colors.textSecondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isImage ? Icons.camera_alt_outlined : Icons.search,
                  size: 20,
                  color: isImage ? AppColors.brandBlue : context.colors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: context.fs(15),
                        fontWeight: FontWeight.w500,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    if (item.createdAt != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(item.createdAt!),
                        style: TextStyle(fontSize: context.fs(12), color: context.colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isImage
                      ? AppColors.brandBlue.withOpacity(0.1)
                      : context.colors.textSecondary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isImage ? '拍照' : '搜索',
                  style: TextStyle(
                    fontSize: context.fs(11),
                    color: isImage ? AppColors.brandBlue : context.colors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: context.colors.textSecondary.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空搜索记录'),
        content: const Text('确定要清空所有搜索记录吗？此操作不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onClearAll?.call();
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, HistoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除记录'),
        content: Text('确定要删除这条${item.searchType == 'image' ? '拍照识别' : '搜索'}记录吗？'),
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
