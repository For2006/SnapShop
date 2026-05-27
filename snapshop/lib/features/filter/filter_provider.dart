import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  FilterNotifier() : super(const FilterState());

  void setFilterText(String text) {
    state = state.copyWith(filterText: text);
  }

  Future<void> submitFilter() async {
    if (state.filterText.trim().isEmpty) return;
    state = state.copyWith(isFiltering: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    state = state.copyWith(isFiltering: false);
  }

  void clearFilter() {
    state = const FilterState();
  }
}

final filterProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});
