import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/sse_client.dart';
import '../../core/network/api_client.dart';
import '../../core/mock_data.dart';

class FilterState {
  final String filterText;
  final bool isFiltering;

  const FilterState({
    this.filterText = '',
    this.isFiltering = false,
  });

  FilterState copyWith({
    String? filterText,
    bool? isFiltering,
  }) {
    return FilterState(
      filterText: filterText ?? this.filterText,
      isFiltering: isFiltering ?? this.isFiltering,
    );
  }
}

class FilterNotifier extends StateNotifier<FilterState> {
  final ApiClient _api = ApiClient();

  FilterNotifier() : super(const FilterState());

  void setFilterText(String text) {
    state = state.copyWith(filterText: text);
  }

  Future<void> submitFilter({
    required String sessionId,
    required void Function(List<MockProduct> products) onProductsUpdated,
  }) async {
    if (state.filterText.trim().isEmpty) return;
    state = state.copyWith(isFiltering: true);

    try {
      final client = SseClient(
        url: '${_api.dio.options.baseUrl}/filter/stream',
        queryParams: {
          'session_id': sessionId,
          'filter_text': state.filterText.trim(),
        },
      );
      final stream = client.connect();
      final products = <MockProduct>[];

      await for (final event in stream) {
        final type = event['type'] as String?;
        if (type == 'product') {
          final productData = event['product'] as Map<String, dynamic>?;
          if (productData != null) {
            products.add(MockProduct.fromJson(productData));
            onProductsUpdated(List.from(products));
          }
        } else if (type == 'done') {
          break;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('[FilterProvider] SSE stream error: $e');
    }

    state = state.copyWith(isFiltering: false);
  }

  void clearFilter() {
    state = const FilterState();
  }
}

final filterProvider =
    StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});
