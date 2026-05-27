import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../core/mock_data.dart';

class SuggestionCard extends StatelessWidget {
  final MockSuggestion suggestion;
  final VoidCallback onTap;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = suggestion.type == 'primary';

    IconData getIcon() {
      switch (suggestion.icon) {
        case 'zap':
          return Icons.bolt;
        case 'trending-down':
          return Icons.trending_down;
        case 'shield-check':
          return Icons.verified_user;
        case 'sparkles':
          return Icons.auto_awesome;
        default:
          return Icons.chevron_right;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFFFF7ED) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? const Color(0xFFFED7AA) : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getIcon(),
              size: 16,
              color: isPrimary ? AppColors.brandBlue : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              suggestion.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPrimary ? AppColors.brandBlue : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
