import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/sse_client.dart';
import '../../core/network/api_client.dart';
import '../../core/mock_data.dart';

@immutable
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
  String toString() => 'FilterState(filterText: "$filterText", isFiltering: $isFiltering)';
}

class FilterNotifier extends Notifier<FilterState> {
  final ApiClient _api = ApiClient();
  SseClient? _sseClient;

  @override
  FilterState build() {
    ref.onDispose(() {
      _sseClient?.close();
      _sseClient = null;
    });
    return const FilterState();
  }

  void setFilterText(String text) {
    state = state.copyWith(filterText: text);
  }

  Future<bool> submitFilter({
    required String sessionId,
    required void Function(List<MockProduct> products) onProductsUpdated,
  }) async {
    if (state.filterText.trim().isEmpty) return false;
    state = state.copyWith(isFiltering: true);

    var lastError = '';
    for (var retry = 0; retry < 3; retry++) {
      if (retry > 0) {
        await Future.delayed(Duration(milliseconds: 500 * retry));
      }
      try {
        final success = await _connect(sessionId, onProductsUpdated);
        if (success) {
          state = state.copyWith(isFiltering: false);
          return true;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('[FilterProvider] SSE attempt $retry failed: $e');
      }
    }

    debugPrint('[FilterProvider] SSE all retries failed: $lastError');
    state = state.copyWith(isFiltering: false);
    return false;
  }

  Future<bool> _connect(
    String sessionId,
    void Function(List<MockProduct> products) onProductsUpdated,
  ) async {
    final deviceId = await ApiClient.getDeviceId();
    final token = ApiClient.accessToken;
    final headers = <String, String>{
      'X-Device-Id': deviceId,
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final client = SseClient(
      url: '${_api.baseUrl}/filter/stream',
      queryParams: {
        'session_id': sessionId,
        'filter_text': state.filterText.trim(),
      },
      headers: headers,
    );
    _sseClient?.close();
    _sseClient = client;
    final stream = client.connect();
    final products = <MockProduct>[];
    var lastUpdate = 0;
    var gotData = false;

    try {
      await for (final event in stream) {
        gotData = true;
        final type = event['type'] as String?;
        if (type == 'product') {
          final productData = event['product'] as Map<String, dynamic>?;
          if (productData != null) {
            products.add(MockProduct.fromJson(productData));
            if (products.length - lastUpdate >= 3) {
              lastUpdate = products.length;
              onProductsUpdated(List.from(products));
            }
          }
        } else if (type == 'done') {
          if (products.length > lastUpdate || products.isEmpty) {
            onProductsUpdated(List.from(products));
          }
          _sseClient?.close();
          _sseClient = null;
          return true;
        } else if (type == 'error') {
          _sseClient?.close();
          _sseClient = null;
          return gotData;
        }
      }
      return gotData;
    } catch (e) {
      _sseClient?.close();
      _sseClient = null;
      rethrow;
    }
  }

  void clearFilter() {
    state = const FilterState();
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  () => FilterNotifier(),
);

final filterTextProvider = Provider<String>((ref) {
  return ref.watch(filterProvider.select((state) => state.filterText));
});

final isFilteringProvider = Provider<bool>((ref) {
  return ref.watch(filterProvider.select((state) => state.isFiltering));
});
