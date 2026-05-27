import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../core/mock_data.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../home/home_provider.dart';
import '../filter/filter_input_bar.dart';
import '../filter/filter_provider.dart';
import '../suggestions/suggestion_list.dart';
import '../product_list/product_card.dart';
import '../product_list/price_summary_bar.dart';
import '../product_list/sort_bar.dart';
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
  SortOption _activeSort = SortOption.comprehensive;

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  void _showAttributeEditSheet(MockAttribute attr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: AttributeEditSheet(
          attribute: attr,
          onSave: (newValue) {
            ref.read(homeProvider.notifier).updateAttribute(attr.key, newValue);
          },
        ),
      ),
    );
  }

  void _onSuggestionTap(MockSuggestion suggestion) {
    final notifier = ref.read(homeProvider.notifier);
    switch (suggestion.action) {
      case 'filter_pdd':
        notifier.filterProducts(platform: 'pdd');
        break;
      case 'sort_price':
        notifier.filterProducts(sort: 'price_asc');
        setState(() => _activeSort = SortOption.priceAsc);
        break;
      case 'filter_official':
        notifier.filterProducts(platform: 'taobao');
        break;
      default:
        notifier.clearFilters();
        setState(() => _activeSort = SortOption.comprehensive);
    }
  }

  void _onSortChanged(SortOption sortKey) {
    setState(() => _activeSort = sortKey);
    switch (sortKey) {
      case SortOption.priceAsc:
        ref.read(homeProvider.notifier).filterProducts(sort: 'price_asc');
        break;
      case SortOption.sales:
        ref.read(homeProvider.notifier).filterProducts(sort: 'sales');
        break;
      default:
        ref.read(homeProvider.notifier).clearFilters();
    }
  }

  void _onFilterSubmit(String text) {
    if (text.trim().isEmpty) return;
    ref.read(filterProvider.notifier).submitFilter().then((_) {
      ref.read(homeProvider.notifier).simulateFilter(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final filterState = ref.watch(filterProvider);
    final isRecognizing = homeState.recognitionStatus == RecognitionStatus.recognizing;

    if (isRecognizing) {
      return const Scaffold(
        body: LoadingIndicator(),
      );
    }

    final recognitionResult = homeState.recognitionResult;
    final products = homeState.products;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: const Text('识别结果'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              if (recognitionResult != null) ...[
                SliverToBoxAdapter(child: _buildRecognitionSection(recognitionResult)),
                SliverToBoxAdapter(child: _buildSuggestions(recognitionResult)),
              ],
              SliverToBoxAdapter(child: _buildSortSection()),
              SliverToBoxAdapter(
                child: PriceSummaryBar(products: products),
              ),
              if (products.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '暂未找到相关商品，试试修改关键词吧',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 14),
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
                      return ProductCard(
                        product: products[index],
                        onTap: () {},
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
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'AI 识别为 '),
                TextSpan(
                  text: result.category,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
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
      color: AppColors.white,
      padding: const EdgeInsets.only(bottom: 12),
      child: SuggestionList(
        suggestions: result.suggestions,
        onTap: _onSuggestionTap,
      ),
    );
  }

  Widget _buildSortSection() {
    return Container(
      color: AppColors.white,
      child: SortBar(
        activeSort: _activeSort,
        onSortChanged: _onSortChanged,
      ),
    );
  }
}
