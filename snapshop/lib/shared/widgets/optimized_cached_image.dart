import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/theme_context.dart';

class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useOldImageOnUrlChange;
  final Duration? fadeInDuration;
  final double? memCacheWidth;
  final double? memCacheHeight;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.useOldImageOnUrlChange = true,
    this.fadeInDuration,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePlaceholder = placeholder ?? _defaultPlaceholder(context);
    final effectiveErrorWidget = errorWidget ?? _defaultErrorWidget(context);

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit ?? BoxFit.cover,
      width: width,
      height: height,
      placeholder: (context, url) => effectivePlaceholder,
      errorWidget: (context, url, error) => effectiveErrorWidget,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 100),
      memCacheWidth: memCacheWidth?.toInt(),
      memCacheHeight: memCacheHeight?.toInt(),
      maxWidthDiskCache: memCacheWidth?.toInt(),
      maxHeightDiskCache: memCacheHeight?.toInt(),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      color: context.colors.cardBg,
    );
  }

  Widget _defaultErrorWidget(BuildContext context) {
    return Container(
      color: context.colors.cardBg,
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 32),
      ),
    );
  }
}
