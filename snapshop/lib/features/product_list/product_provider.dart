import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mock_data.dart';

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
  List<MockProduct> _fullProducts = [];

  ProductListNotifier() : super(const ProductListState());

  void sortProducts(String sortBy) {
    var products = List<MockProduct>.from(_fullProducts.isNotEmpty ? _fullProducts : state.products);
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
      case 'comprehensive':
        break;
    }
    state = state.copyWith(products: products, sortBy: sortBy);
  }

  void filterByPlatform(String? platform) {
    var products = List<MockProduct>.from(_fullProducts.isNotEmpty ? _fullProducts : state.products);
    if (platform != null) {
      products = products.where((p) => p.platform == platform).toList();
      state = state.copyWith(products: products, filterPlatform: platform);
    } else {
      products = List<MockProduct>.from(_fullProducts);
      state = state.copyWith(products: products, filterPlatform: null);
    }
  }

  void updateProducts(List<MockProduct> products) {
    _fullProducts = List<MockProduct>.from(products);
    state = state.copyWith(products: products);
  }
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>((ref) {
  return ProductListNotifier();
});
