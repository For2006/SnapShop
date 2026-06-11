import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../core/mock_data.dart';

class SuggestionCard extends StatelessWidget {
  final MockSuggestion suggestion;
  final VoidCallback onTap;
  final bool isSelected;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onTap,
    this.isSelected = false,
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
        case 'palette':
          return Icons.palette;
        case 'star':
          return Icons.star;
        case 'check-circle':
          return Icons.check_circle;
        case 'search':
          return Icons.search;
        case 'filter':
          return Icons.filter_alt;
        case 'sliders':
          return Icons.tune;
        case 'tag':
          return Icons.local_offer;
        case 'verified':
          return Icons.verified;
        default:
          return Icons.chevron_right;
      }
    }

    Color getBackgroundColor() {
      if (isSelected) {
        return AppColors.brandBlue.withValues(alpha: 0.1);
      }
      return isPrimary ? const Color(0xFFFFF7ED) : context.colors.surface;
    }

    Color getBorderColor() {
      if (isSelected) {
        return AppColors.brandBlue;
      }
      return isPrimary ? const Color(0xFFFED7AA) : context.colors.divider;
    }

    Color getIconColor() {
      if (isSelected) {
        return AppColors.brandBlue;
      }
      return isPrimary ? AppColors.brandBlue : context.colors.textSecondary;
    }

    Color getTextColor() {
      if (isSelected) {
        return AppColors.brandBlue;
      }
      return isPrimary ? AppColors.brandBlue : context.colors.textSecondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: (isPrimary ? AppColors.brandBlue : context.colors.textPrimary).withValues(alpha: 0.12),
        highlightColor: (isPrimary ? AppColors.brandBlue : context.colors.textPrimary).withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: getBorderColor(),
              width: 1.2,
            ),
            boxShadow: isPrimary && !isSelected ? [
              BoxShadow(
                color: const Color(0xFFFF9500).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                getIcon(),
                size: 18,
                color: getIconColor(),
              ),
              const SizedBox(width: 8),
              Text(
                suggestion.title,
                style: TextStyle(
                  fontSize: context.fs(13),
                  fontWeight: FontWeight.w600,
                  color: getTextColor(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
