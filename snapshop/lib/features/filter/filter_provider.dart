import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/mock_data.dart';

class FilterCard {
  final String id;
  final String label;
  final String key;
  final dynamic value;
  final bool active;

  const FilterCard({required this.id, required this.label, required this.key, required this.value, this.active = true});

  FilterCard copyWith({String? id, String? label, String? key, dynamic value, bool? active}) {
    return FilterCard(
      id: id ?? this.id,
      label: label ?? this.label,
      key: key ?? this.key,
      value: value ?? this.value,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'label': label, 'key': key, 'value': value, 'active': active};

  factory FilterCard.fromJson(Map<String, dynamic> json) {
    return FilterCard(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      value: json['value'],
      active: json['active'] != false,
    );
  }
}

@immutable
class FilterState {
  final String filterText;
  final bool isFiltering;
  final Map<String, dynamic> activeFilters;
  final List<FilterCard> filterCards;
  final List<MockProduct>? originalProducts;

  const FilterState({
    this.filterText = '',
    this.isFiltering = false,
    this.activeFilters = const {},
    this.filterCards = const [],
    this.originalProducts,
  });

  FilterState copyWith({
    String? filterText,
    bool? isFiltering,
    Map<String, dynamic>? activeFilters,
    List<FilterCard>? filterCards,
    List<MockProduct>? originalProducts,
    bool clearOriginal = false,
  }) {
    return FilterState(
      filterText: filterText ?? this.filterText,
      isFiltering: isFiltering ?? this.isFiltering,
      activeFilters: activeFilters ?? this.activeFilters,
      filterCards: filterCards ?? this.filterCards,
      originalProducts: clearOriginal ? null : (originalProducts ?? this.originalProducts),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterState &&
          runtimeType == other.runtimeType &&
          filterText == other.filterText &&
          isFiltering == other.isFiltering;

  @override
  int get hashCode => Object.hash(filterText, isFiltering);

  @override
  String toString() => 'FilterState(filterText: "$filterText", isFiltering: $isFiltering, cards: ${filterCards.length})';
}

class FilterNotifier extends Notifier<FilterState> {
  final ApiClient _api = ApiClient();

  @override
  FilterState build() {
    return const FilterState();
  }

  void setFilterText(String text) {
    state = state.copyWith(filterText: text);
  }

  void setOriginalProducts(List<MockProduct> products) {
    state = state.copyWith(originalProducts: products);
  }

  static List<MockProduct> applyFilters(Map<String, dynamic> filters, List<MockProduct> products) {
    var result = List<MockProduct>.from(products);

    if (filters.isEmpty) return result;

    if (filters['price_min'] != null) {
      final min = (filters['price_min'] as num).toDouble();
      result = result.where((p) => p.price >= min).toList();
    }
    if (filters['price_max'] != null) {
      final max = (filters['price_max'] as num).toDouble();
      result = result.where((p) => p.price <= max).toList();
    }
    if (filters['color'] != null) {
      final color = filters['color'].toString();
      result = result.where((p) {
        final name = p.name.toLowerCase();
        final searchColor = color.toLowerCase();
        if (name.contains(searchColor)) return true;
        final attrs = p.attributes;
        if (attrs.isNotEmpty) {
          for (final v in attrs.values) {
            if (v != null && v.toString().toLowerCase().contains(searchColor)) return true;
          }
        }
        return false;
      }).toList();
    }
    if (filters['brand'] != null) {
      final brand = filters['brand'].toString().toLowerCase();
      result = result.where((p) {
        if (p.name.toLowerCase().contains(brand)) return true;
        final attrs = p.attributes;
        if (attrs.isNotEmpty) {
          for (final v in attrs.values) {
            if (v != null && v.toString().toLowerCase().contains(brand)) return true;
          }
        }
        return false;
      }).toList();
    }
    if (filters['shop_type'] != null) {
      final st = filters['shop_type'].toString();
      result = result.where((p) => p.shopType == st).toList();
    }
    if (filters['min_rating'] != null) {
      final minRating = (filters['min_rating'] as num).toDouble();
      result = result.where((p) => p.rating >= minRating).toList();
    }
    if (filters['sort_by'] != null) {
      result = _sortProducts(result, filters['sort_by'].toString());
    }

    return result;
  }

  static List<MockProduct> _sortProducts(List<MockProduct> products, String sortBy) {
    final list = List<MockProduct>.from(products);
    switch (sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating_desc':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'sales':
      case 'sales_desc':
        list.sort((a, b) => b.salesCount.compareTo(a.salesCount));
        break;
    }
    return list;
  }

  static List<FilterCard> filtersToCards(Map<String, dynamic> filters) {
    final cards = <FilterCard>[];
    if (filters['price_max'] != null) {
      cards.add(FilterCard(id: 'price_max', label: '${(filters['price_max'] as num).toInt()}元以内', key: 'price_max', value: filters['price_max']));
    }
    if (filters['price_min'] != null) {
      cards.add(FilterCard(id: 'price_min', label: '${(filters['price_min'] as num).toInt()}元以上', key: 'price_min', value: filters['price_min']));
    }
    if (filters['color'] != null) {
      cards.add(FilterCard(id: 'color', label: filters['color'].toString(), key: 'color', value: filters['color']));
    }
    if (filters['brand'] != null) {
      cards.add(FilterCard(id: 'brand', label: filters['brand'].toString(), key: 'brand', value: filters['brand']));
    }
    if (filters['shop_type'] != null) {
      const shopMap = {'official': '官方旗舰店', 'self_operated': '自营', 'exclusive': '专卖店'};
      final st = filters['shop_type'].toString();
      cards.add(FilterCard(id: 'shop_type', label: shopMap[st] ?? st, key: 'shop_type', value: st));
    }
    if (filters['min_rating'] != null) {
      cards.add(FilterCard(id: 'min_rating', label: '${filters['min_rating']}分+', key: 'min_rating', value: filters['min_rating']));
    }
    return cards;
  }

  static Map<String, dynamic> _localRegexParse(String text) {
    final filters = <String, dynamic>{};

    final priceRange = RegExp(r'(\d+)\s*[-~到至]\s*(\d+)\s*元?');
    final priceMax = RegExp(r'(\d+)\s*元?\s*(以内|以下|不超过)');
    final priceMin = RegExp(r'(\d+)\s*元?\s*(以上|不低于)');
    final ratingMatch = RegExp(r'(\d+(?:\.\d+)?)\s*分?\s*[+＋以上]');

    final pr = priceRange.firstMatch(text);
    if (pr != null) {
      filters['price_min'] = double.tryParse(pr.group(1)!);
      filters['price_max'] = double.tryParse(pr.group(2)!);
    } else {
      final pm = priceMax.firstMatch(text);
      if (pm != null) filters['price_max'] = double.tryParse(pm.group(1)!);
      final pn = priceMin.firstMatch(text);
      if (pn != null) filters['price_min'] = double.tryParse(pn.group(1)!);
    }

    final rm = ratingMatch.firstMatch(text);
    if (rm != null) filters['min_rating'] = double.tryParse(rm.group(1)!);

    const colors = ['黑色', '白色', '红色', '蓝色', '绿色', '黄色', '紫色', '粉色', '灰色', '棕色', '橙色', '银色', '金色'];
    for (final c in colors) {
      if (text.contains(c)) { filters['color'] = c; break; }
    }

    if (text.contains('自营')) filters['shop_type'] = 'self_operated';
    else if (text.contains('旗舰店') || text.contains('官方')) filters['shop_type'] = 'official';

    const sortMap = {'价格从低到高': 'price_asc', '价格从高到低': 'price_desc', '好评': 'rating_desc', '评价': 'rating_desc', '销量': 'sales'};
    for (final e in sortMap.entries) {
      if (text.contains(e.key)) { filters['sort_by'] = e.value; break; }
    }

    return filters;
  }

  Future<bool> submitFilter({
    required String sessionId,
    required void Function(List<MockProduct> products) onProductsUpdated,
  }) async {
    if (state.filterText.trim().isEmpty) return false;
    state = state.copyWith(isFiltering: true);

    Map<String, dynamic> filters;
    List<FilterCard> cards;

    try {
      final response = await _api.post('/filter', data: {
        'session_id': sessionId,
        'filter_text': state.filterText.trim(),
      });
      final data = response.data;
      if (data is Map<String, dynamic>) {
        filters = Map<String, dynamic>.from(data['filters'] as Map? ?? {});
        final rawCards = data['cards'] as List<dynamic>? ?? [];
        cards = rawCards.map((c) => FilterCard.fromJson(c as Map<String, dynamic>)).toList();
      } else {
        filters = _localRegexParse(state.filterText.trim());
        cards = filtersToCards(filters);
      }
    } catch (e) {
      debugPrint('[FilterProvider] POST /filter failed, using local regex: $e');
      filters = _localRegexParse(state.filterText.trim());
      cards = filtersToCards(filters);
    }

    final baseProducts = state.originalProducts ?? [];
    final filtered = applyFilters(filters, baseProducts);
    onProductsUpdated(filtered);

    state = state.copyWith(
      isFiltering: false,
      activeFilters: filters,
      filterCards: cards,
    );
    return true;
  }

  void removeFilter(String cardId) {
    final newFilters = Map<String, dynamic>.from(state.activeFilters);
    newFilters.remove(cardId);
    final newCards = state.filterCards.where((c) => c.id != cardId).toList();

    final base = state.originalProducts ?? [];
    final filtered = applyFilters(newFilters, base);

    state = state.copyWith(
      activeFilters: newFilters,
      filterCards: newCards,
    );
  }

  void clearAllFilters({void Function(List<MockProduct>)? onRestore}) {
    final originals = state.originalProducts;
    if (onRestore != null && originals != null) {
      onRestore(originals);
    }
    state = FilterState(
      filterText: state.filterText,
      originalProducts: state.originalProducts,
    );
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  () => FilterNotifier(),
);
