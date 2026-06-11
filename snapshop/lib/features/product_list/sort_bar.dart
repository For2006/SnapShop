import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';

enum SortOption {
  comprehensive,
  priceAsc,
  priceDesc,
  sales,
  rating,
}

class SortBar extends StatelessWidget {
  final SortOption? activeSort;
  final Function(SortOption) onSortChanged;

  const SortBar({
    super.key,
    required this.activeSort,
    required this.onSortChanged,
  });

  List<({SortOption key, String label})> _buildSortOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      (key: SortOption.comprehensive, label: l10n.sortComprehensive),
      (key: SortOption.priceAsc, label: l10n.sortPriceAsc),
      (key: SortOption.priceDesc, label: l10n.sortPriceDesc),
      (key: SortOption.sales, label: l10n.sortSales),
      (key: SortOption.rating, label: l10n.sortRating),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = _buildSortOptions(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          bottom: BorderSide(color: context.colors.cardBg),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: sortOptions.map((option) {
            final isActive = activeSort == option.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSortChanged(option.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.brandBlue.withValues(alpha: 0.1) : context.colors.secondaryBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? AppColors.brandBlue : context.colors.divider,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.brandBlue : context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
