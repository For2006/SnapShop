import 'package:flutter/material.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
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
            Icon(Icons.access_time, size: 16, color: context.colors.textTertiary),
            const SizedBox(width: 6),
            Text(
              AppLocalizations.of(context).searchHistory,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: context.colors.textSecondary,
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
                avatar: Icon(Icons.search, size: 14, color: context.colors.textTertiary),
                label: Text(item, style: TextStyle(fontSize: context.fs(13))),
                backgroundColor: context.colors.secondaryBg,
                side: BorderSide(color: context.colors.divider),
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
