import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/l10n/app_localizations.dart';
import '../../config/theme_context.dart';

enum ErrorType { general, network, server, empty, permission }

class ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final ErrorType errorType;
  final String? retryLabel;

  const ErrorRetry({
    super.key,
    required this.message,
    required this.onRetry,
    this.errorType = ErrorType.general,
    this.retryLabel,
  });

  IconData get _icon {
    switch (errorType) {
      case ErrorType.network:
        return Icons.wifi_off_rounded;
      case ErrorType.server:
        return Icons.dns_outlined;
      case ErrorType.empty:
        return Icons.inbox_outlined;
      case ErrorType.permission:
        return Icons.lock_outlined;
      case ErrorType.general:
        return Icons.error_outline_rounded;
    }
  }

  Color get _iconColor {
    switch (errorType) {
      case ErrorType.network:
        return AppColors.accentOrange;
      case ErrorType.server:
        return AppColors.errorRed;
      case ErrorType.empty:
        return AppColors.textTertiary;
      case ErrorType.permission:
        return AppColors.warningAmber;
      case ErrorType.general:
        return AppColors.textTertiary;
    }
  }

  String get _defaultTitle {
    switch (errorType) {
      case ErrorType.network:
        return '网络连接失败';
      case ErrorType.server:
        return '服务器异常';
      case ErrorType.empty:
        return '暂无内容';
      case ErrorType.permission:
        return '权限不足';
      case ErrorType.general:
        return '出错了';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveRetryLabel = retryLabel ?? l10n.retry;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 34, color: _iconColor),
            ),
            const SizedBox(height: 20),
            Text(
              _defaultTitle,
              style: TextStyle(
                fontSize: context.fs(17),
                fontWeight: FontWeight.w600,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: context.fs(14),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(effectiveRetryLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
