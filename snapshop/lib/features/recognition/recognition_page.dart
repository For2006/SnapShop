import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme_context.dart';
import '../../config/l10n/app_localizations.dart';
import '../../core/mock_data.dart';
import '../../core/mock_products.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/widgets/error_retry.dart';
import '../home/home_provider.dart';
import '../filter/filter_input_bar.dart';
import '../filter/filter_provider.dart';
import '../suggestions/suggestion_list.dart';
import '../product_list/product_card.dart';
import '../product_list/product_detail_page.dart';
import '../product_list/price_summary_bar.dart';
import '../product_list/sort_bar.dart';
import '../product_list/product_provider.dart';
import '../settings/settings_provider.dart';
import 'widgets/attribute_chip.dart';
import 'attribute_edit_sheet.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class RecognitionPage extends ConsumerStatefulWidget {
  const RecognitionPage({super.key});

  @override
  ConsumerState<RecognitionPage> createState() => _RecognitionPageState();
}

class _RecognitionPageState extends ConsumerState<RecognitionPage> {
  final TextEditingController _filterController = TextEditingController();
  final ApiClient _api = ApiClient();
  SortOption _activeSort = SortOption.comprehensive;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _navigateToProductDetail(MockProduct product) {
    context.push('/product-detail', extra: {
      'product': product,
      'initialIsFavorited': ref.read(settingsProvider).favoriteProductIds.contains(product.id),
    });
  }

  void _showAttributeEditSheet(MockAttribute attr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: AttributeEditSheet(
          attribute: attr,
          onSave: (newValue) {
            _updateAttribute(attr.key, newValue);
          },
        ),
      ),
    );
  }

  Future<void> _updateAttribute(String key, String newValue) async {
    final notifier = ref.read(homeProvider.notifier);
    notifier.updateAttribute(key, newValue);

    final sessionId = ref.read(homeProvider).sessionId;
    if (sessionId == null) return;

    try {
      final response = await _api.patch(
        '/recognize/$sessionId/attributes',
        data: {'attribute': key, 'new_value': newValue},
      );
      final raw = response.data;
      if (raw is! Map<String, dynamic>) {
        debugPrint('[RecognitionPage] 属性更新响应格式异常: ${raw.runtimeType}');
        return;
      }
      final data = raw;
      final products = (data['products'] as List<dynamic>?)
              ?.map((e) => MockProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (products.isNotEmpty) {
        notifier.updateProductsAfterAttributeEdit(products);
        ref.read(productListProvider.notifier).updateProducts(products);
      }
      final updatedAttrs = (data['updated_attributes'] as List<dynamic>?);
      if (updatedAttrs != null && updatedAttrs.isNotEmpty) {
        notifier.updateRecognitionAttributes(updatedAttrs);
      }
    } catch (e) {
      debugPrint('[RecognitionPage] _updateAttribute 失败: $e');
    }
  }

  Future<void> _onSuggestionTap(MockSuggestion? suggestion) async {
    final notifier = ref.read(homeProvider.notifier);
    final productNotifier = ref.read(productListProvider.notifier);

    if (suggestion == null) {
      notifier.clearFilters();
      productNotifier.updateProducts(ref.read(homeProvider).products);
      if (mounted) {
        setState(() => _activeSort = SortOption.comprehensive);
      }
      return;
    }

    if (mounted) {
      setState(() => _activeSort = SortOption.comprehensive);
    }

    final currentProducts = ref.read(productListProvider).products.isNotEmpty
        ? ref.read(productListProvider).products
        : ref.read(homeProvider).products;
    switch (suggestion.action) {
      case 'filter_pdd':
        notifier.filterProducts(platform: 'pdd', baseProducts: currentProducts);
        break;
      case 'sort_price':
        notifier.filterProducts(sort: 'price_asc', baseProducts: currentProducts);
        break;
      case 'filter_official':
        notifier.filterProducts(shopType: 'official', baseProducts: currentProducts);
        break;
      default:
        notifier.clearFilters();
        productNotifier.updateProducts([]);
        if (mounted) {
          setState(() => _activeSort = SortOption.comprehensive);
        }
        return;
    }
    productNotifier.updateProducts(ref.read(homeProvider).products);

    final sessionId = ref.read(homeProvider).sessionId;
    if (sessionId != null) {
      try {
        final response = await _api.post('/suggestions/action', data: {
          'session_id': sessionId,
          'card_id': suggestion.id,
          'params': _buildSuggestionParams(suggestion),
        });
        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          final data = raw;
          final products = (data['products'] as List<dynamic>?)
                  ?.map((e) => MockProduct.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          if (products.isNotEmpty) {
            productNotifier.updateProducts(products);
          }
        }
      } catch (e) {
        debugPrint('[RecognitionPage] _onSuggestionTap API 后备: $e');
      }
    }
  }

  Map<String, dynamic> _buildSuggestionParams(MockSuggestion suggestion) {
    switch (suggestion.action) {
      case 'sort_price':
        return {'sort_by': 'price_asc'};
      case 'filter_official':
        return {'shop_type': 'official'};
      case 'filter_pdd':
        return {'platform': 'pdd'};
      default:
        return {};
    }
  }

  void _onSortChanged(SortOption sortKey) {
    setState(() => _activeSort = sortKey);

    final homeNotifier = ref.read(homeProvider.notifier);
    final productNotifier = ref.read(productListProvider.notifier);

    homeNotifier.clearFilters();
    productNotifier.updateProducts(ref.read(homeProvider).products);

    if (ref.read(productListProvider).products.isEmpty) {
      productNotifier.updateProducts(ref.read(homeProvider).products);
    }

    String sortBy;
    switch (sortKey) {
      case SortOption.priceAsc:
        sortBy = 'price_asc';
        break;
      case SortOption.priceDesc:
        sortBy = 'price_desc';
        break;
      case SortOption.sales:
        sortBy = 'sales';
        break;
      case SortOption.rating:
        sortBy = 'rating_desc';
        break;
      default:
        sortBy = 'comprehensive';
    }
    productNotifier.sortProducts(sortBy);
  }

  void _onFilterSubmit(String text) {
    if (text.trim().isEmpty) return;
    final sessionId = ref.read(homeProvider).sessionId;
    final l10n = AppLocalizations.of(context);
    if (sessionId == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.filterNoSession),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.okLabel),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _activeSort = SortOption.comprehensive);

    final currentProducts = ref.read(productListProvider).products.isNotEmpty
        ? ref.read(productListProvider).products
        : ref.read(homeProvider).products;

    ref.read(filterProvider.notifier).setFilterText(text);
    ref.read(filterProvider.notifier).setOriginalProducts(currentProducts);

    ref.read(filterProvider.notifier).submitFilter(
      sessionId: sessionId,
      onProductsUpdated: (products) {
        ref.read(productListProvider.notifier).updateProducts(products);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(homeProvider, (prev, next) {
      if (prev != null &&
          prev.recognitionStatus != RecognitionStatus.recognizing &&
          next.recognitionStatus == RecognitionStatus.recognizing) {
        ref.read(productListProvider.notifier).updateProducts([]);
        _activeSort = SortOption.comprehensive;
      }
      if (prev != null &&
          prev.recognitionStatus == RecognitionStatus.recognizing &&
          next.recognitionStatus == RecognitionStatus.completed &&
          next.products.isNotEmpty) {
        ref.read(productListProvider.notifier).updateProducts(next.products);
        ref.read(productListProvider.notifier).sortProducts('comprehensive');
      }
      if (prev != null &&
          prev.recognitionStatus == RecognitionStatus.completed &&
          next.recognitionStatus == RecognitionStatus.completed &&
          prev.products.isEmpty && next.products.isNotEmpty) {
        ref.read(productListProvider.notifier).updateProducts(next.products);
      }
    });

    final homeState = ref.watch(homeProvider);
    final filterState = ref.watch(filterProvider);
    final productState = ref.watch(productListProvider);
    final l10n = AppLocalizations.of(context);
    final isRecognizing =
        homeState.recognitionStatus == RecognitionStatus.recognizing;

    if (isRecognizing) {
      return Scaffold(
        body: LoadingIndicator(imagePath: homeState.selectedImagePath),
      );
    }

    if (homeState.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.recognitionTitle),
          leading: IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => context.pop(),
          ),
        ),
        body: ErrorRetry(
          message: homeState.errorMessage!,
          onRetry: () {
            final notifier = ref.read(homeProvider.notifier);
            if (notifier.isTextOperation) {
              final query = ref.read(homeProvider).searchQuery;
              if (query.isNotEmpty) {
                notifier.submitTextSearch(query);
              }
            } else {
              notifier.startRecognition();
            }
          },
        ),
      );
    }

    final recognitionResult = homeState.recognitionResult;
    var products = productState.products.isNotEmpty
        ? productState.products
        : homeState.products;
    if (products.isEmpty && recognitionResult != null) {
      products = MockProductData.getByCategory(recognitionResult.category);
    }

    return Scaffold(
      backgroundColor: context.colors.primaryBg,
      appBar: AppBar(
        title: Text(l10n.recognitionTitle),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              if (recognitionResult != null) ...[
                SliverToBoxAdapter(
                    child: _buildRecognitionSection(recognitionResult)),
                SliverToBoxAdapter(
                    child: _buildSuggestions(recognitionResult)),
              ],
              SliverToBoxAdapter(child: _buildSortSection()),
              if (filterState.filterCards.isNotEmpty)
                SliverToBoxAdapter(child: _buildFilterCardsSection()),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PriceSummaryHeaderDelegate(
                  products: products,
                  onPlatformTap: (platform) {
                    ref.read(homeProvider.notifier).filterProducts(platform: platform);
                  },
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      filterState.filterCards.isNotEmpty
                          ? l10n.filterEmptyResult
                          : l10n.recognitionEmpty,
                      style: TextStyle(
                          color: context.colors.textTertiary,
                          fontSize: context.fs(14)),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverMasonryGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isFavorited: ref.read(settingsProvider).favoriteProductIds.contains(product.id),
                        onTap: () => _navigateToProductDetail(product),
                        onFavoriteChanged: () => ref.read(settingsProvider.notifier).refreshStats(),
                      );
                    },
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Material(
              color: Colors.transparent,
              child: FilterInputBar(
                controller: _filterController,
                isLoading: filterState.isFiltering,
                onSubmit: _onFilterSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCardsSection() {
    final filterNotifier = ref.read(filterProvider.notifier);
    final cards = ref.watch(filterProvider).filterCards;

    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          ...cards.map((card) => GestureDetector(
            onTap: () {
              ref.read(filterProvider.notifier).removeFilter(card.id);
              final base = ref.read(filterProvider).originalProducts ?? [];
              final newFilters = Map<String, dynamic>.from(ref.read(filterProvider).activeFilters);
              newFilters.remove(card.id);
              final filtered = FilterNotifier.applyFilters(newFilters, base);
              ref.read(productListProvider.notifier).updateProducts(filtered);
            },
            child: Chip(
              label: Text(card.label, style: TextStyle(fontSize: context.fs(12))),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                ref.read(filterProvider.notifier).removeFilter(card.id);
                final base = ref.read(filterProvider).originalProducts ?? [];
                final newFilters = Map<String, dynamic>.from(ref.read(filterProvider).activeFilters);
                newFilters.remove(card.id);
                final filtered = FilterNotifier.applyFilters(newFilters, base);
                ref.read(productListProvider.notifier).updateProducts(filtered);
              },
              backgroundColor: context.colors.secondaryBg,
              side: BorderSide(color: context.colors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )),
          GestureDetector(
            onTap: () {
              ref.read(filterProvider.notifier).clearAllFilters(
                onRestore: (originals) {
                  ref.read(productListProvider.notifier).updateProducts(originals);
                },
              );
            },
            child: Chip(
              label: Text(AppLocalizations.of(context).filterClearAll, style: TextStyle(fontSize: context.fs(12), color: context.colors.textSecondary)),
              backgroundColor: Colors.transparent,
              side: BorderSide(color: context.colors.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecognitionSection(MockRecognitionResult result) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: TextStyle(
                  fontSize: context.fs(14),
                  color: context.colors.textSecondary),
              children: [
                TextSpan(
                    text: AppLocalizations.of(context).recognitionAiLabel),
                TextSpan(
                  text: result.category,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: result.attributes.map((attr) {
              return AttributeChip(
                attribute: attr,
                onTap: () => _showAttributeEditSheet(attr),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(MockRecognitionResult result) {
    return Container(
      color: context.colors.surface,
      padding: const EdgeInsets.only(bottom: 12),
      child: SuggestionList(
        suggestions: result.suggestions,
        onTap: _onSuggestionTap,
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      color: context.colors.surface,
      child: SortBar(
        activeSort: _activeSort,
        onSortChanged: _onSortChanged,
      ),
    );
  }
}

class _PriceSummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<MockProduct> products;
  final void Function(String platform)? onPlatformTap;

  _PriceSummaryHeaderDelegate({required this.products, this.onPlatformTap});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return PriceSummaryBar(products: products, onPlatformTap: onPlatformTap);
  }

  @override
  double get maxExtent {
    if (products.isEmpty) return 0.0;
    final platforms = <String>{};
    for (final p in products) {
      platforms.add(p.platform);
    }
    return platforms.length > 1 ? 108.0 : 54.0;
  }

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _PriceSummaryHeaderDelegate oldDelegate) {
    return products != oldDelegate.products ||
        onPlatformTap != oldDelegate.onPlatformTap;
  }
}
