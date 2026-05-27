import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/mock_data.dart';

enum RecognitionStatus { idle, recognizing, completed }

class HomeState {
  final String searchQuery;
  final bool isGalleryOpen;
  final bool isHistoryOpen;
  final RecognitionStatus recognitionStatus;
  final MockRecognitionResult? recognitionResult;
  final List<MockProduct> products;
  final String? activeFilter;
  final String? activeSort;

  const HomeState({
    this.searchQuery = '',
    this.isGalleryOpen = false,
    this.isHistoryOpen = false,
    this.recognitionStatus = RecognitionStatus.idle,
    this.recognitionResult,
    this.products = mockProducts,
    this.activeFilter,
    this.activeSort,
  });

  HomeState copyWith({
    String? searchQuery,
    bool? isGalleryOpen,
    bool? isHistoryOpen,
    RecognitionStatus? recognitionStatus,
    MockRecognitionResult? recognitionResult,
    List<MockProduct>? products,
    String? activeFilter,
    String? activeSort,
    bool clearFilter = false,
    bool clearSort = false,
  }) {
    return HomeState(
      searchQuery: searchQuery ?? this.searchQuery,
      isGalleryOpen: isGalleryOpen ?? this.isGalleryOpen,
      isHistoryOpen: isHistoryOpen ?? this.isHistoryOpen,
      recognitionStatus: recognitionStatus ?? this.recognitionStatus,
      recognitionResult: recognitionResult ?? this.recognitionResult,
      products: products ?? this.products,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      activeSort: clearSort ? null : (activeSort ?? this.activeSort),
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleGallery() {
    state = state.copyWith(isGalleryOpen: !state.isGalleryOpen);
  }

  void closeGallery() {
    state = state.copyWith(isGalleryOpen: false);
  }

  void openHistory() {
    state = state.copyWith(isHistoryOpen: true, isGalleryOpen: false);
  }

  void closeHistory() {
    state = state.copyWith(isHistoryOpen: false);
  }

  Future<void> startRecognition() async {
    state = state.copyWith(recognitionStatus: RecognitionStatus.recognizing);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.completed,
      recognitionResult: mockRecognitionResult,
      products: mockProducts,
    );
  }

  void updateAttribute(String key, String newValue) {
    final result = state.recognitionResult;
    if (result == null) return;

    final newAttrs = result.attributes.map((attr) {
      if (attr.key == key) {
        return attr.copyWith(value: newValue, confidence: 1.0);
      }
      return attr;
    }).toList();

    state = state.copyWith(
      recognitionResult: MockRecognitionResult(
        category: result.category,
        attributes: newAttrs,
        suggestions: result.suggestions,
      ),
    );
  }

  void filterProducts({String? platform, String? sort}) {
    var newProducts = List<MockProduct>.from(mockProducts);

    if (platform != null) {
      newProducts = newProducts.where((p) => p.platform == platform).toList();
      state = state.copyWith(activeFilter: platform);
    }

    if (sort == 'price_asc') {
      newProducts.sort((a, b) => a.price.compareTo(b.price));
      state = state.copyWith(activeSort: sort);
    }

    state = state.copyWith(products: newProducts);
  }

  void clearFilters() {
    state = state.copyWith(
      products: mockProducts,
      clearFilter: true,
      clearSort: true,
    );
  }

  void simulateFilter(String filterText) {
    state = state.copyWith(
      products: mockProducts.where((p) => p.platform == 'taobao').toList(),
      activeFilter: 'taobao',
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
