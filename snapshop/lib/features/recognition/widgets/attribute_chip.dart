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

  bool get _isLowConfidence => attribute.confidence < 0.7;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _isLowConfidence
              ? AppColors.warningAmberBg
              : AppColors.successGreenBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isLowConfidence
                ? AppColors.warningAmberBorder
                : AppColors.successGreenBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${attribute.label}: ',
              style: TextStyle(
                fontSize: context.fs(12),
                color: _isLowConfidence
                    ? AppColors.warningAmber
                    : AppColors.successGreen,
              ),
            ),
            Text(
              attribute.value,
              style: TextStyle(
                fontSize: context.fs(12),
                fontWeight: FontWeight.w600,
                color: _isLowConfidence
                    ? AppColors.warningAmber
                    : AppColors.successGreen,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              _isLowConfidence ? Icons.warning_amber_rounded : Icons.check_circle,
              size: 14,
              color: _isLowConfidence
                  ? AppColors.warningAmber
                  : AppColors.successGreen.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}
