import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';

class PriceSummaryBar extends StatelessWidget {
  final List<MockProduct> products;

  const PriceSummaryBar({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final platformData = _groupByPlatform();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: context.colors.cardBg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        l10n.priceAllPlatforms,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: context.colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${products.length}',
                      style: TextStyle(
                        fontSize: context.fs(14),
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        l10n.priceItemsFound,
                        style: TextStyle(
                          fontSize: context.fs(14),
                          color: context.colors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildPriceLabel(l10n.priceLowest, '\u00a5${_overallMinPrice().toStringAsFixed(0)}', AppColors.priceRed),
              const SizedBox(width: 12),
              _buildPriceLabel(l10n.priceAverage, '\u00a5${_overallAvgPrice().round()}', context.colors.textSecondary),
            ],
          ),
          if (platformData.length > 1) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: platformData.entries.map((entry) {
                final platform = entry.key;
                final data = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: context.colors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        platform,
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${data.count}\u4ef6',
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: context.colors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\u00a5${data.minPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.fs(11),
                          fontWeight: FontWeight.w700,
                          color: AppColors.priceRed,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\u5747\u00a5${data.avgPrice.round()}',
                        style: TextStyle(
                          fontSize: context.fs(10),
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  double _overallMinPrice() {
    return products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
  }

  double _overallAvgPrice() {
    return products.fold(0.0, (sum, p) => sum + p.price) / products.length;
  }

  Map<String, _PlatformPriceData> _groupByPlatform() {
    final map = <String, List<MockProduct>>{};
    for (final p in products) {
      final platform = p.platform.isNotEmpty ? p.platform : '\u5176\u4ed6';
      map.putIfAbsent(platform, () => []).add(p);
    }
    final result = <String, _PlatformPriceData>{};
    for (final entry in map.entries) {
      final list = entry.value;
      final minPrice = list.map((p) => p.price).reduce((a, b) => a < b ? a : b);
      final avgPrice = list.fold(0.0, (sum, p) => sum + p.price) / list.length;
      result[entry.key] = _PlatformPriceData(
        count: list.length,
        minPrice: minPrice,
        avgPrice: avgPrice,
      );
    }
    return result;
  }

  Widget _buildPriceLabel(String label, String price, Color priceColor) {
    return Builder(
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: context.fs(11),
                color: context.colors.textTertiary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              price,
              style: TextStyle(
                fontSize: context.fs(15),
                fontWeight: FontWeight.w600,
                color: priceColor,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlatformPriceData {
  final int count;
  final double minPrice;
  final double avgPrice;

  const _PlatformPriceData({
    required this.count,
    required this.minPrice,
    required this.avgPrice,
  });
}
