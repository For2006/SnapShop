import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../core/mock_data.dart';

class SearchHistorySection extends StatelessWidget {
  final void Function(String item)? onItemTap;

  const SearchHistorySection({super.key, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              '搜索记录',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: mockHistory.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = mockHistory[index];
              return ActionChip(
                avatar: Icon(Icons.search, size: 14, color: AppColors.textTertiary),
                label: Text(item, style: const TextStyle(fontSize: 13)),
                backgroundColor: AppColors.secondaryBg,
                side: BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                onPressed: () => onItemTap?.call(item),
              );
            },
          ),
        ),
      ],
    );
  }
}
