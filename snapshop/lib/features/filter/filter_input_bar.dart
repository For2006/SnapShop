import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';

class FilterInputBar extends StatefulWidget {
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
  State<FilterInputBar> createState() => _FilterInputBarState();
}

class _FilterInputBarState extends State<FilterInputBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isFocused ? AppColors.brandBlue : context.colors.divider,
          width: _isFocused ? 1.5 : 0.5,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _isFocused ? AppColors.brandBlue.withValues(alpha: 0.1) : context.colors.secondaryBg,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.tune,
              size: 20,
              color: _isFocused ? AppColors.brandBlue : context.colors.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              onSubmitted: (value) => widget.onSubmit(value),
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
              textInputAction: TextInputAction.search,
            ),
          ),
          if (widget.isLoading)
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (widget.controller.text.trim().isNotEmpty) {
                  widget.onSubmit(widget.controller.text.trim());
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.controller.text.trim().isNotEmpty
                      ? AppColors.brandBlue
                      : context.colors.secondaryBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: widget.controller.text.trim().isNotEmpty
                      ? Colors.white
                      : context.colors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
