import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border(
          top: BorderSide(
            color: context.colors.divider,
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
              color: context.colors.secondaryBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: context.colors.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (value) => onSubmit(value),
              style: TextStyle(fontSize: context.fs(14), color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.filterPlaceholder,
                hintStyle: TextStyle(color: context.colors.textTertiary, fontSize: context.fs(13)),
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
                color: context.colors.secondaryBg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 20,
                color: context.colors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
