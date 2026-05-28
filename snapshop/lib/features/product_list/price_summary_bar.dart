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
    final minPrice = products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final avgPrice = products.fold(0.0, (sum, p) => sum + p.price) / products.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: context.colors.cardBg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                l10n.priceAllPlatforms,
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: context.colors.textSecondary,
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
              Text(
                l10n.priceItemsFound,
                style: TextStyle(
                  fontSize: context.fs(14),
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildPriceLabel(l10n.priceLowest, '\u00a5${minPrice.toStringAsFixed(0)}', AppColors.priceRed),
              const SizedBox(width: 16),
              _buildPriceLabel(l10n.priceAverage, '\u00a5${avgPrice.round()}', context.colors.textSecondary),
            ],
          ),
        ],
      ),
    );
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
