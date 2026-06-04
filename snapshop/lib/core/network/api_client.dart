import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  static const _deviceIdKey = 'snapshop_device_id';
  static const _tokenKey = 'snapshop_access_token';
  static String? _deviceId;
  static String? _accessToken;
  static Future<String>? _deviceIdFuture;

  late final Dio dio;

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://127.0.0.1:8000/api/v1',
      ),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: kDebugMode,
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

  Future<Response> uploadFile(String path, File file) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(file.path, filename: 'image.jpg'),
    });
    return dio.post(path, data: formData);
  }
}
