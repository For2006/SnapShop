import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/mock_data.dart';
import '../../core/network/api_client.dart' show ApiClient, AppException;
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

  CancelToken? _recognizeCancelToken;
  CancelToken? _pollCancelToken;
  int _pollAttempts = 0;
  static const int _maxPollAttempts = 20;
  static const Duration _pollInterval = Duration(milliseconds: 1500);

  Future<void> startRecognition({File? imageFile}) async {
    // 防止重复提交识别请求
    if (state.recognitionStatus == RecognitionStatus.recognizing) return;
    
    // 取消上一个未完成的识别请求
    _recognizeCancelToken?.cancel('新的识别请求已发起');
    _recognizeCancelToken = CancelToken();
    _pollCancelToken?.cancel('新的识别请求已发起');
    
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
      bool isTempCompressedFile = false;
      final bytes = await sourceFile.readAsBytes();
      // 限制最大上传文件大小，超过5MB直接压缩
      if (await ImageCompress.shouldCompress(bytes) || bytes.length > 5 * 1024 * 1024) {
        final compressed = await ImageCompress.compress(bytes);
        final tempDir = await getTemporaryDirectory();
        final compressedFile = File('${tempDir.path}/compress_recognize_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await compressedFile.writeAsBytes(compressed);
        uploadFile = compressedFile;
        isTempCompressedFile = true;
        debugPrint('[HomeProvider] 图片压缩: ${bytes.length} -> ${compressed.length} bytes');
      }
      final response = await _api.uploadFile(
        '/recognize', 
        uploadFile,
        fieldName: 'image',
        cancelToken: _recognizeCancelToken,
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint('[HomeProvider] 响应格式异常: ${data.runtimeType}');
        state = state.copyWith(
          recognitionStatus: RecognitionStatus.completed,
          errorMessage: '服务器返回数据异常，请稍后重试',
        );
        // 后台异步清理临时文件，不阻塞页面跳转
        if (isTempCompressedFile) {
          uploadFile.exists().then((exists) {
            if (exists) uploadFile.delete();
          });
        }
        return;
      }
      // 立即更新状态触发页面跳转，不等待文件删除
      _handleApiResponse(data);
      // 后台异步清理临时文件，完全不阻塞主流程
      if (isTempCompressedFile) {
        uploadFile.exists().then((exists) {
          if (exists) uploadFile.delete();
        });
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('[HomeProvider] 识别请求已取消');
        state = state.copyWith(recognitionStatus: RecognitionStatus.idle);
        return;
      }
      String message = _extractDioError(e, '识别失败');
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

  String _extractDioError(DioException e, String fallback) {
    if (e.error is AppException) {
      final msg = (e.error as AppException).message;
      if (msg == '发生未知错误') {
        return '$fallback（网络异常，请重试）';
      }
      return msg;
    }
    if (e.response != null) {
      final detail = e.response!.data;
      if (detail is Map<String, dynamic>) {
        final msg = detail['message']?.toString();
        if (msg != null && msg.isNotEmpty) return msg;
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络后重试';
      case DioExceptionType.sendTimeout:
        return '发送超时，请检查网络后重试';
      case DioExceptionType.receiveTimeout:
        return '服务器响应超时，请检查网络后重试';
      case DioExceptionType.connectionError:
        return '无法连接服务器，请检查：\n1. 手机网络是否正常\n2. 后端服务是否已启动\n3. API地址配置是否正确';
      case DioExceptionType.badCertificate:
        return 'SSL证书验证失败';
      default:
        return '$fallback（${e.type.name}）';
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
      String message = _extractDioError(e, '搜索失败');
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

    final needPoll = products.isEmpty && sessionId != null && _lastOperationType == _OperationType.image;

    state = state.copyWith(
      recognitionStatus: needPoll ? RecognitionStatus.recognizing : RecognitionStatus.completed,
      recognitionResult: MockRecognitionResult.fromJson(data),
      products: products,
      sessionId: sessionId,
      clearFilter: true,
      clearSort: true,
    );

    if (needPoll) {
      _pollProducts(sessionId);
    }
  }

  Future<void> _pollProducts(String sessionId) async {
    _pollCancelToken?.cancel();
    _pollCancelToken = CancelToken();
    _pollAttempts = 0;

    while (_pollAttempts < _maxPollAttempts) {
      if (_pollCancelToken!.isCancelled) return;
      await Future.delayed(_pollInterval);
      if (_pollCancelToken!.isCancelled) return;
      _pollAttempts++;

      try {
        final response = await _api.get('/products/$sessionId', queryParameters: {'page': 1, 'size': 50});
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final items = data['items'] as List<dynamic>? ?? [];
          if (items.isNotEmpty) {
            final products = items.map((e) => MockProduct.fromJson(e as Map<String, dynamic>)).toList();
            _handleProductsPollResult(products);
            return;
          }
        }
      } catch (e) {
        debugPrint('[HomeProvider] 轮询商品失败 (attempt $_pollAttempts): $e');
      }
    }
    debugPrint('[HomeProvider] 轮询商品超时，$_maxPollAttempts次未获取到结果');
    if (state.recognitionStatus == RecognitionStatus.recognizing) {
      state = state.copyWith(recognitionStatus: RecognitionStatus.completed);
    }
  }

  void _handleProductsPollResult(List<MockProduct> products) {
    _originalProducts = null;
    state = state.copyWith(
      recognitionStatus: RecognitionStatus.completed,
      products: products,
    );
  }

  void updateAttribute(String key, String newValue) {
    final result = state.recognitionResult;
    if (result == null) return;

    final newAttrs = result.attributes.map((attr) {
      if (attr.key == key) {
        return attr.copyWith(value: newValue);
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

  void updateProductsAfterAttributeEdit(List<MockProduct> products) {
    _originalProducts = null;
    state = state.copyWith(products: products);
  }

  void updateRecognitionAttributes(List<dynamic> attrsList) {
    final result = state.recognitionResult;
    if (result == null) return;

    final attrs = attrsList.map((a) {
      final m = a as Map<String, dynamic>;
      return MockAttribute(
        key: m['key']?.toString() ?? '',
        label: m['label']?.toString() ?? '',
        value: m['value']?.toString() ?? '',
      );
    }).toList();

    state = state.copyWith(
      recognitionResult: MockRecognitionResult(
        category: result.category,
        attributes: attrs,
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

final recognitionStatusProvider = Provider<RecognitionStatus>((ref) {
  return ref.watch(homeProvider.select((state) => state.recognitionStatus));
});

final recognitionResultProvider = Provider<MockRecognitionResult?>((ref) {
  return ref.watch(homeProvider.select((state) => state.recognitionResult));
});

final productsProvider = Provider<List<MockProduct>>((ref) {
  return ref.watch(homeProvider.select((state) => state.products));
});
