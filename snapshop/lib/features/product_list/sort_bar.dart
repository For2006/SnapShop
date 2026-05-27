import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

enum SortOption {
  comprehensive,
  priceAsc,
  sales,
}

class SortBar extends StatelessWidget {
  final SortOption? activeSort;
  final Function(SortOption) onSortChanged;

  const SortBar({
    super.key,
    required this.activeSort,
    required this.onSortChanged,
  });

  static final _sortOptions = <({SortOption key, String label})>[
    (key: SortOption.comprehensive, label: '综合推荐'),
    (key: SortOption.priceAsc, label: '价格从低到高'),
    (key: SortOption.sales, label: '销量优先'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.cardBg),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _sortOptions.map((option) {
            final isActive = activeSort == option.key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSortChanged(option.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.brandBlue.withValues(alpha: 0.1) : AppColors.secondaryBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive ? AppColors.brandBlue : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? AppColors.brandBlue : AppColors.textSecondary,
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
