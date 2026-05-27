import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class PlatformBadge extends StatelessWidget {
  final String platform;

  const PlatformBadge({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    final (Color bgColor, String label) = switch (platform) {
      'taobao' => (AppColors.taobaoOrange, '淘宝'),
      'jd' => (AppColors.jdRed, '京东'),
      'pdd' => (AppColors.pddRed, '拼多多'),
      _ => (AppColors.textTertiary, platform),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
