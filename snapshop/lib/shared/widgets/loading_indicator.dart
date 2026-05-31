import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/l10n/app_localizations.dart';

class LoadingIndicator extends StatefulWidget {
  final String? imagePath;

  const LoadingIndicator({super.key, this.imagePath});

  @override
  State<LoadingIndicator> createState() => _LoadingIndicatorState();
}

class _LoadingIndicatorState extends State<LoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _scanController;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkBgPrimary,
            AppColors.darkBgSecondary,
            AppColors.darkBgPrimary,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScanningImage(),
            const SizedBox(height: 40),
            Text(
              l10n.loadingTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.loadingSubtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningImage() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _scanController,
        builder: (context, child) {
          return Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 2,
              ),
              color: Colors.white.withValues(alpha: 0.05),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: widget.imagePath != null
                      ? Image.file(
                          File(widget.imagePath!),
                          width: 160,
                          height: 160,
                          fit: BoxFit.cover,
                          color: Colors.white.withValues(alpha: 0.6),
                          colorBlendMode: BlendMode.overlay,
                        )
                      : Container(
                          width: 160,
                          height: 160,
                          color: AppColors.darkBgSecondary,
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            color: Color(0xFF60A5FA),
                            size: 48,
                          ),
                        ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 160 * _scanController.value,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0xFF60A5FA),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF3B82F6).withValues(alpha: 0.8),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFF3B82F6)
                              .withValues(alpha: 0.2),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delayedValue =
                (_dotsController.value + index * 0.33) % 1.0;
            final scale = 1.0 +
                0.2 *
                    (delayedValue < 0.5
                        ? delayedValue * 2
                        : (1 - delayedValue) * 2);
            final opacity = 0.3 +
                0.7 *
                    (delayedValue < 0.5
                        ? delayedValue * 2
                        : (1 - delayedValue) * 2);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF60A5FA).withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
