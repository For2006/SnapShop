import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../core/mock_data.dart';

class PriceSummaryBar extends StatelessWidget {
  final List<MockProduct> products;

  const PriceSummaryBar({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    final minPrice = products.map((p) => p.price).reduce((a, b) => a < b ? a : b);
    final avgPrice = products.fold(0.0, (sum, p) => sum + p.price) / products.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(color: AppColors.cardBg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                '全网 ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${products.length}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                ' 款同款',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              _buildPriceLabel('最低价', '\u00a5${minPrice.toStringAsFixed(0)}', AppColors.priceRed),
              const SizedBox(width: 16),
              _buildPriceLabel('均价', '\u00a5${avgPrice.round()}', AppColors.textSecondary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLabel(String label, String price, Color priceColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          price,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: priceColor,
          ),
        ),
      ],
    );
  }
}
