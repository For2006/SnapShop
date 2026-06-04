import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mock_data.dart';

@immutable
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
      filterPlatform: clearFilter ? null : (filterPlatform ?? this.filterPlatform),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductListState &&
          runtimeType == other.runtimeType &&
          listEquals(products, other.products) &&
          sortBy == other.sortBy &&
          filterPlatform == other.filterPlatform;

  @override
  int get hashCode => Object.hash(products, sortBy, filterPlatform);

  @override
  String toString() =>
      'ProductListState(products: ${products.length}, sortBy: $sortBy, filterPlatform: $filterPlatform)';
}

class ProductListNotifier extends Notifier<ProductListState> {
  List<MockProduct> _fullProducts = [];

  @override
  ProductListState build() {
    return const ProductListState();
  }

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

  void reset() {
    _fullProducts = [];
    state = const ProductListState();
  }
}

final productListProvider = NotifierProvider<ProductListNotifier, ProductListState>(
  () => ProductListNotifier(),
);

final productCountProvider = Provider<int>((ref) {
  return ref.watch(productListProvider.select((state) => state.products.length));
});

final currentSortProvider = Provider<String?>((ref) {
  return ref.watch(productListProvider.select((state) => state.sortBy));
});

final currentFilterProvider = Provider<String?>((ref) {
  return ref.watch(productListProvider.select((state) => state.filterPlatform));
});
