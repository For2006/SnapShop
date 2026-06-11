import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/theme_context.dart';
import '../../../core/mock_data.dart';

class AttributeChip extends StatelessWidget {
  final MockAttribute attribute;
  final VoidCallback onTap;

  const AttributeChip({
    super.key,
    required this.attribute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.successGreenBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.successGreenBorder,
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  '${attribute.label}: ${attribute.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.fs(12),
                    color: AppColors.successGreen,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.check_circle,
                size: 14,
                color: AppColors.successGreen.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
