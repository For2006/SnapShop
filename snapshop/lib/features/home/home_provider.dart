import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/image_compress.dart';

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
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ApiClient _api = ApiClient();

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

  Future<void> startRecognition({File? imageFile}) async {
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.recognizing,
      clearError: true,
      selectedImagePath: imageFile?.path,
    );
    try {
      final File? sourceFile = imageFile ??
          (state.selectedImagePath != null
              ? File(state.selectedImagePath!)
              : null);
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
      _handleRecognizeResponse(data);
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
      _handleSearchResponse(data);
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

  void _handleRecognizeResponse(Map<String, dynamic> data) {
    final sessionId = data['session_id']?.toString();
    final products = (data['products'] as List<dynamic>?)
            ?.map((e) => MockProduct.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.completed,
      recognitionResult: MockRecognitionResult.fromJson(data),
      products: products,
      sessionId: sessionId,
    );
  }

  void _handleSearchResponse(Map<String, dynamic> data) {
    final sessionId = data['session_id']?.toString();
    final products = (data['products'] as List<dynamic>?)
            ?.map((e) => MockProduct.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.completed,
      recognitionResult: MockRecognitionResult.fromJson(data),
      products: products,
      sessionId: sessionId,
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
    var newProducts = List<MockProduct>.from(state.products);
    if (platform != null) {
      newProducts = newProducts.where((p) => p.platform == platform).toList();
    }
    if (sort == 'price_asc') {
      newProducts.sort((a, b) => a.price.compareTo(b.price));
    }
    state = state.copyWith(
      activeFilter: platform,
      activeSort: sort,
      products: newProducts,
    );
  }

  void clearFilters() {
    state = state.copyWith(clearFilter: true, clearSort: true);
  }

  void simulateFilter(String filterText) {
    state = state.copyWith(
      products: state.products.where((p) => p.platform == 'taobao').toList(),
      activeFilter: 'taobao',
    );
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
