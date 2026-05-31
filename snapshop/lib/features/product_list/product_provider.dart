import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart';

class ProductListState {
  final List<MockProduct> products;
  final String? sortBy;
  final String? filterPlatform;

  const ProductListState({
    this.products = const [],
    this.sortBy,
    this.filterPlatform,
  });

  ProductListState copyWith({
    List<MockProduct>? products,
    String? sortBy,
    String? filterPlatform,
    bool clearSort = false,
    bool clearFilter = false,
  }) {
    return ProductListState(
      products: products ?? this.products,
      sortBy: clearSort ? null : (sortBy ?? this.sortBy),
      filterPlatform:
          clearFilter ? null : (filterPlatform ?? this.filterPlatform),
    );
  }
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ApiClient _api = ApiClient();

  ProductListNotifier() : super(const ProductListState());

  Future<void> sortProducts(String sortBy, String? sessionId) async {
    if (sessionId == null) return;
    try {
      final response = await _api.get(
        '/products/$sessionId',
        queryParameters: {'sort_by': sortBy, 'page': 1, 'size': 50},
      );
      final data = response.data as Map<String, dynamic>;
      final products = (data['items'] as List<dynamic>?)
              ?.map(
                  (e) => MockProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      state = state.copyWith(products: products, sortBy: sortBy);
    } catch (e) {
      debugPrint('[ProductListNotifier] sortProducts 失败: $e');
      _localSort(sortBy);
    }
  }

  void _localSort(String sortBy) {
    var products = List<MockProduct>.from(state.products);
    switch (sortBy) {
      case 'price_asc':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'sales':
        products.sort((a, b) => b.salesCount.compareTo(a.salesCount));
        break;
    }
    state = state.copyWith(products: products, sortBy: sortBy);
  }

  Future<void> filterByPlatform(String? platform, String? sessionId) async {
    if (sessionId != null && platform != null) {
      try {
        final response = await _api.get(
          '/products/$sessionId',
          queryParameters: {'platform': platform, 'page': 1, 'size': 50},
        );
        final data = response.data as Map<String, dynamic>;
        final products = (data['items'] as List<dynamic>?)
                ?.map(
                    (e) => MockProduct.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        state =
            state.copyWith(products: products, filterPlatform: platform);
        return;
      } catch (e) {
        debugPrint('[ProductListNotifier] filterByPlatform 失败: $e');
      }
    }

    var products = List<MockProduct>.from(state.products);
    if (platform != null) {
      products = products.where((p) => p.platform == platform).toList();
    }
    state = state.copyWith(products: products, filterPlatform: platform);
  }

  void updateProducts(List<MockProduct> products) {
    state = state.copyWith(products: products);
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier();
});
