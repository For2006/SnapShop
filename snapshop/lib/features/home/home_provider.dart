import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/image_compress.dart';

enum RecognitionStatus { idle, recognizing, completed }

enum _OperationType { image, text }

@immutable
class HomeState {
  final String searchQuery;
  final bool isGalleryOpen;
  final bool isHistoryOpen;
  final RecognitionStatus recognitionStatus;
  final MockRecognitionResult? recognitionResult;
  final List<MockProduct> products;
  final String? activeFilter;
  final String? activeSort;
  final String? sessionId;
  final String? errorMessage;
  final String? selectedImagePath;

  const HomeState({
    this.searchQuery = '',
    this.isGalleryOpen = false,
    this.isHistoryOpen = false,
    this.recognitionStatus = RecognitionStatus.idle,
    this.recognitionResult,
    this.products = const [],
    this.activeFilter,
    this.activeSort,
    this.sessionId,
    this.errorMessage,
    this.selectedImagePath,
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
    String? sessionId,
    String? errorMessage,
    String? selectedImagePath,
    bool clearFilter = false,
    bool clearSort = false,
    bool clearError = false,
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
      sessionId: sessionId ?? this.sessionId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          isGalleryOpen == other.isGalleryOpen &&
          isHistoryOpen == other.isHistoryOpen &&
          recognitionStatus == other.recognitionStatus &&
          recognitionResult == other.recognitionResult &&
          listEquals(products, other.products) &&
          activeFilter == other.activeFilter &&
          activeSort == other.activeSort &&
          sessionId == other.sessionId &&
          errorMessage == other.errorMessage &&
          selectedImagePath == other.selectedImagePath;

  @override
  int get hashCode => Object.hash(
        searchQuery,
        isGalleryOpen,
        isHistoryOpen,
        recognitionStatus,
        recognitionResult,
        products,
        activeFilter,
        activeSort,
        sessionId,
        errorMessage,
        selectedImagePath,
      );

  @override
  String toString() =>
      'HomeState(status: $recognitionStatus, products: ${products.length}, sessionId: $sessionId)';
}

class HomeNotifier extends Notifier<HomeState> {
  final ApiClient _api = ApiClient();
  List<MockProduct>? _originalProducts;
  _OperationType _lastOperationType = _OperationType.image;

  @override
  HomeState build() {
    return const HomeState();
  }

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

  Future<void> startRecognition({File? imageFile}) async {
    _lastOperationType = _OperationType.image;
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.recognizing,
      clearError: true,
      selectedImagePath: imageFile?.path,
    );
    try {
      File? sourceFile;
      if (imageFile != null) {
        sourceFile = imageFile;
      } else if (state.selectedImagePath != null) {
        final f = File(state.selectedImagePath!);
        if (await f.exists()) {
          sourceFile = f;
        }
      }
      if (sourceFile == null) {
        state = state.copyWith(
          recognitionStatus: RecognitionStatus.completed,
          errorMessage: '没有找到图片文件',
        );
        return;
      }
      File uploadFile = sourceFile;
      final bytes = await sourceFile.readAsBytes();
      if (await ImageCompress.shouldCompress(bytes)) {
        final compressed = await ImageCompress.compress(bytes);
        final tempDir = await getTemporaryDirectory();
        final compressedFile = File('${tempDir.path}/compress_recognize.jpg');
        await compressedFile.writeAsBytes(compressed);
        uploadFile = compressedFile;
        debugPrint('[HomeProvider] 图片压缩: ${bytes.length} -> ${compressed.length} bytes');
      }
      final response = await _api.uploadFile('/recognize', uploadFile);
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint('[HomeProvider] 响应格式异常: ${data.runtimeType}');
        state = state.copyWith(
          recognitionStatus: RecognitionStatus.completed,
          errorMessage: '服务器返回数据异常，请稍后重试',
        );
        return;
      }
      _handleApiResponse(data);
    } on DioException catch (e) {
      String message = '识别失败，请检查网络后重试';
      if (e.response != null) {
        final detail = e.response!.data;
        if (detail is Map<String, dynamic>) {
          message = detail['message']?.toString() ?? message;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = '网络连接超时，请检查网络后重试';
      } else if (e.type == DioExceptionType.connectionError) {
        message = '无法连接服务器，请确认手机与电脑在同一网络';
      }
      state = state.copyWith(
        recognitionStatus: RecognitionStatus.completed,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        recognitionStatus: RecognitionStatus.completed,
        errorMessage: '识别失败：$e',
      );
    }
  }

  Future<void> submitTextSearch(String query) async {
    if (query.trim().isEmpty) return;
    _lastOperationType = _OperationType.text;
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.recognizing,
      clearError: true,
    );
    try {
      final response = await _api.post('/search', data: {
        'keywords': [query.trim()],
      });
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint('[HomeProvider] 响应格式异常: ${data.runtimeType}');
        state = state.copyWith(
          recognitionStatus: RecognitionStatus.completed,
          errorMessage: '服务器返回数据异常，请稍后重试',
        );
        return;
      }
      _handleApiResponse(data);
    } on DioException catch (e) {
      String message = '搜索失败，请检查网络后重试';
      if (e.response != null) {
        final detail = e.response!.data;
        if (detail is Map<String, dynamic>) {
          message = detail['message']?.toString() ?? message;
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = '网络连接超时，请检查网络后重试';
      } else if (e.type == DioExceptionType.connectionError) {
        message = '无法连接服务器，请确认手机与电脑在同一网络';
      }
      state = state.copyWith(
        recognitionStatus: RecognitionStatus.completed,
        errorMessage: message,
      );
    } catch (e) {
      state = state.copyWith(
        recognitionStatus: RecognitionStatus.completed,
        errorMessage: '搜索失败：$e',
      );
    }
  }

  void _handleApiResponse(Map<String, dynamic> data) {
    final sessionId = data['session_id']?.toString();
    final products = (data['products'] as List<dynamic>?)
            ?.map((e) => MockProduct.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    _originalProducts = null;
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.completed,
      recognitionResult: MockRecognitionResult.fromJson(data),
      products: products,
      sessionId: sessionId,
      clearFilter: true,
      clearSort: true,
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

  void filterProducts({String? platform, String? sort, String? shopType, List<MockProduct>? baseProducts}) {
    if (_originalProducts == null || baseProducts != null) {
      _originalProducts = List<MockProduct>.from(baseProducts ?? state.products);
    }
    var newProducts = List<MockProduct>.from(_originalProducts!);
    final effectivePlatform = platform ?? state.activeFilter;
    final effectiveSort = sort ?? state.activeSort;
    if (effectivePlatform != null) {
      newProducts = newProducts.where((p) => p.platform == effectivePlatform).toList();
    }
    if (shopType != null) {
      newProducts = newProducts.where((p) => p.shopType == shopType).toList();
    }
    if (effectiveSort == 'price_asc') {
      newProducts.sort((a, b) => a.price.compareTo(b.price));
    } else if (effectiveSort == 'price_desc') {
      newProducts.sort((a, b) => b.price.compareTo(a.price));
    } else if (effectiveSort == 'sales') {
      newProducts.sort((a, b) => b.salesCount.compareTo(a.salesCount));
    }
    state = state.copyWith(
      activeFilter: effectivePlatform,
      activeSort: effectiveSort,
      products: newProducts,
    );
  }

  void clearFilters() {
    if (_originalProducts != null) {
      state = state.copyWith(
        clearFilter: true,
        clearSort: true,
        products: _originalProducts,
      );
      _originalProducts = null;
    } else {
      state = state.copyWith(clearFilter: true, clearSort: true);
    }
  }

  bool get isTextOperation => _lastOperationType == _OperationType.text;
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(
  () => HomeNotifier(),
);

final searchQueryProvider = Provider<String>((ref) {
  return ref.watch(homeProvider.select((state) => state.searchQuery));
});

final recognitionStatusProvider = Provider<RecognitionStatus>((ref) {
  return ref.watch(homeProvider.select((state) => state.recognitionStatus));
});

final recognitionResultProvider = Provider<MockRecognitionResult?>((ref) {
  return ref.watch(homeProvider.select((state) => state.recognitionResult));
});

final productsProvider = Provider<List<MockProduct>>((ref) {
  return ref.watch(homeProvider.select((state) => state.products));
});

final productCountProvider = Provider<int>((ref) {
  return ref.watch(homeProvider.select((state) => state.products.length));
});

final sessionIdProvider = Provider<String?>((ref) {
  return ref.watch(homeProvider.select((state) => state.sessionId));
});

final errorMessageProvider = Provider<String?>((ref) {
  return ref.watch(homeProvider.select((state) => state.errorMessage));
});

final isGalleryOpenProvider = Provider<bool>((ref) {
  return ref.watch(homeProvider.select((state) => state.isGalleryOpen));
});

final isHistoryOpenProvider = Provider<bool>((ref) {
  return ref.watch(homeProvider.select((state) => state.isHistoryOpen));
});

final activeFilterProvider = Provider<String?>((ref) {
  return ref.watch(homeProvider.select((state) => state.activeFilter));
});

final activeSortProvider = Provider<String?>((ref) {
  return ref.watch(homeProvider.select((state) => state.activeSort));
});
