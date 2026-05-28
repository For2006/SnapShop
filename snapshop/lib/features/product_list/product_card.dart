import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';
import '../../shared/widgets/platform_badge.dart';

class ProductCard extends StatelessWidget {
  final MockProduct product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: context.colors.cardBg,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: PlatformBadge(platform: product.platform),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: context.fs(12),
                      color: context.colors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (product.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: product.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: context.fs(9),
                              color: AppColors.priceRed,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\u00a5',
                            style: TextStyle(
                              fontSize: context.fs(11),
                              fontWeight: FontWeight.w700,
                              color: AppColors.priceRed,
                            ),
                          ),
                          Text(
                            '${product.price}',
                            style: TextStyle(
                              fontSize: context.fs(20),
                              fontWeight: FontWeight.w700,
                              color: AppColors.priceRed,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l10n.formatSalesCount(product.salesCount),
                        style: TextStyle(
                          fontSize: context.fs(9),
                          color: context.colors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
