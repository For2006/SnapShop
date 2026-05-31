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
    context.push('/product-detail', extra: product);
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
        ref.read(productListProvider.notifier).updateProducts(products);
      }
    } catch (e) {
      debugPrint('[RecognitionPage] _updateAttribute 失败: $e');
    }
  }

  Future<void> _onSuggestionTap(MockSuggestion suggestion) async {
    final notifier = ref.read(homeProvider.notifier);
    final sessionId = ref.read(homeProvider).sessionId;

    if (sessionId != null) {
      try {
        final response = await _api.post('/suggestions/action', data: {
          'session_id': sessionId,
          'card_id': suggestion.id,
          'params': _buildSuggestionParams(suggestion),
        });
        final data = response.data as Map<String, dynamic>;
        final products = (data['products'] as List<dynamic>?)
                ?.map(
                    (e) => MockProduct.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        if (products.isNotEmpty) {
          ref.read(productListProvider.notifier).updateProducts(products);
          return;
        }
      } catch (e) {
        debugPrint('[RecognitionPage] _onSuggestionTap 接口失败: $e');
      }
    }

    switch (suggestion.action) {
      case 'filter_pdd':
        notifier.filterProducts(platform: 'pdd');
        break;
      case 'sort_price':
        notifier.filterProducts(sort: 'price_asc');
        break;
      case 'filter_official':
        notifier.filterProducts(platform: 'taobao');
        break;
      default:
        notifier.clearFilters();
        setState(() => _activeSort = SortOption.comprehensive);
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
    final sessionId = ref.read(homeProvider).sessionId;
    String sortBy;
    switch (sortKey) {
      case SortOption.priceAsc:
        sortBy = 'price_asc';
        break;
      case SortOption.sales:
        sortBy = 'sales';
        break;
      default:
        sortBy = 'comprehensive';
    }
    ref.read(productListProvider.notifier).sortProducts(sortBy, sessionId);
  }

  void _onFilterSubmit(String text) {
    if (text.trim().isEmpty) return;
    final sessionId = ref.read(homeProvider).sessionId;
    if (sessionId == null) return;

    ref.read(filterProvider.notifier).setFilterText(text);

    ref.read(filterProvider.notifier).submitFilter(
      sessionId: sessionId,
      onProductsUpdated: (products) {
        ref.read(productListProvider.notifier).updateProducts(products);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
            final query = ref.read(homeProvider).searchQuery;
            if (query.isNotEmpty) {
              ref.read(homeProvider.notifier).submitTextSearch(query);
            } else {
              ref.read(homeProvider.notifier).startRecognition();
            }
          },
        ),
      );
    }

    final recognitionResult = homeState.recognitionResult;
    // 1. API 返回的商品优先  2. API 无返回则从本地 mock 库按分类筛选  3. 都没有则空
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
              SliverToBoxAdapter(
                child: PriceSummaryBar(products: products),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.recognitionEmpty,
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
                        onTap: () => _navigateToProductDetail(product),
                      );
                    },
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: FilterInputBar(
              controller: _filterController,
              isLoading: filterState.isFiltering,
              onSubmit: _onFilterSubmit,
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
