import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class FilterInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSubmit;

  const FilterInputBar({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondaryBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (value) => onSubmit(value),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '自然语言筛选，如「500元以内自营」',
                hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                isDense: true,
              ),
            ),
          ),
          if (isLoading)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandBlue,
                ),
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondaryBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
