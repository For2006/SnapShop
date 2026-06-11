import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AppException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException({super.message = '网络连接失败，请检查网络设置', super.originalError});
}

class TimeoutException extends AppException {
  TimeoutException({super.message = '请求超时，请稍后重试', super.originalError});
}

class ServerException extends AppException {
  ServerException({super.message = '服务器异常，请稍后重试', super.statusCode, super.originalError});
}

class UnauthorizedException extends AppException {
  UnauthorizedException({super.message = '登录已过期，请重新登录', super.statusCode = 401, super.originalError});
}

class BadRequestException extends AppException {
  BadRequestException({required super.message, super.statusCode = 400, super.originalError});
}

class NotFoundException extends AppException {
  NotFoundException({super.message = '服务暂不可用，请稍后重试', super.statusCode = 404, super.originalError});
}

class UnknownException extends AppException {
  UnknownException({super.message = '发生未知错误', super.originalError});
}

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 3),
    ],
  });

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] as int? ?? 0;

    if (retryCount < retries && _shouldRetry(err)) {
      final delay = retryDelays[retryCount.clamp(0, retryDelays.length - 1)];
      await Future.delayed(delay);

      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } catch (e) {
        return super.onError(err, handler);
      }
    }

    return super.onError(err, handler);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null &&
            err.response!.statusCode! >= 500);
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static const _deviceIdKey = 'snapshop_device_id';
  static const _tokenKey = 'snapshop_access_token';
  static const _customBaseUrlKey = 'snapshop_custom_base_url';
  // TODO: 替换为你的阿里云服务器公网 IP
  static const _productionBaseUrl = 'http://localhost:8000/api/v1';
  static String? _deviceId;
  static String? _accessToken;
  static String? _customBaseUrl;
  static Future<String>? _deviceIdFuture;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: _getDefaultBaseUrl(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(RetryInterceptor(
      dio: dio,
      retries: 3,
      retryDelays: const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 3),
      ],
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        final exception = _handleDioError(error);
        handler.reject(DioException(
          requestOptions: error.requestOptions,
          error: exception,
          type: error.type,
          response: error.response,
          message: error.message,
        ));
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        options.headers['X-Device-Id'] = await _getDeviceId();
        if (_accessToken != null && _accessToken!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        handler.next(options);
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: kDebugMode,
    ));
  }

  static String _getDefaultBaseUrl() {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    if (kReleaseMode) {
      return _productionBaseUrl;
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static Future<void> initFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customBaseUrl = prefs.getString(_customBaseUrlKey);
      _accessToken = prefs.getString(_tokenKey);
      if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
        _instance.dio.options.baseUrl = _customBaseUrl!;
      }
    } catch (_) {}
  }

  static Future<void> setCustomBaseUrl(String newUrl) async {
    _customBaseUrl = newUrl;
    _instance.dio.options.baseUrl = newUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customBaseUrlKey, newUrl);
  }

  static Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(originalError: error);
      case DioExceptionType.badCertificate:
        return NetworkException(message: 'SSL证书验证失败', originalError: error);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final serverMessage = _extractServerMessage(error.response?.data);
        switch (statusCode) {
          case 400:
            return BadRequestException(
              message: serverMessage ?? '请求参数错误',
              statusCode: statusCode,
              originalError: error,
            );
          case 401:
            return UnauthorizedException(
              message: serverMessage ?? '登录已过期，请重新登录',
              statusCode: statusCode,
              originalError: error,
            );
          case 404:
            return NotFoundException(
              message: serverMessage ?? '请求的资源不存在',
              originalError: error,
            );
          case 409:
            return AppException(
              message: serverMessage ?? '资源冲突，请检查后重试',
              statusCode: statusCode,
              originalError: error,
            );
          case 429:
            return AppException(
              message: serverMessage ?? '请求过于频繁，请稍后重试',
              statusCode: statusCode,
              originalError: error,
            );
          case 500:
          case 502:
          case 503:
            return ServerException(
              message: serverMessage ?? '服务器繁忙，请稍后重试',
              statusCode: statusCode,
              originalError: error,
            );
          default:
            return AppException(
              message: serverMessage ?? '请求失败，状态码: $statusCode',
              statusCode: statusCode,
              originalError: error,
            );
        }
      case DioExceptionType.cancel:
        return UnknownException(message: '请求已取消', originalError: error);
      case DioExceptionType.connectionError:
        return NetworkException(originalError: error);
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return NetworkException(originalError: error);
        }
        return UnknownException(originalError: error);
    }
  }

  static String? _extractServerMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
      final detail = data['detail'];
      if (detail is Map<String, dynamic>) {
        return detail['message']?.toString();
      }
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }

  static Future<void> setToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_tokenKey);
  }

  static Future<String> _getDeviceId() async {
    if (_deviceId != null) return _deviceId!;
    if (_deviceIdFuture != null) {
      try {
        return await _deviceIdFuture!;
      } catch (_) {
        _deviceIdFuture = null;
      }
    }
    _deviceIdFuture = _initDeviceId();
    try {
      return await _deviceIdFuture!;
    } catch (_) {
      _deviceIdFuture = null;
      rethrow;
    }
  }

  static Future<String> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = '${DateTime.now().millisecondsSinceEpoch}-${(DateTime.now().microsecondsSinceEpoch % 1000000)}';
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
    return _deviceId!;
  }

  static Future<String> getDeviceId() => _getDeviceId();

  static String? get accessToken => _accessToken;

  String get baseUrl => dio.options.baseUrl;

  Future<Response> post(String path, {dynamic data}) async {
    return dio.post(path, data: data);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return dio.delete(path);
  }

  Future<Response> uploadFile(String path, File file, {String fieldName = 'image', CancelToken? cancelToken}) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(file.path, filename: 'image.jpg'),
    });
    return dio.post(path, data: formData, cancelToken: cancelToken);
  }
}
