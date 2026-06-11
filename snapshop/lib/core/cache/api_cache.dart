import 'dart:async';

class ApiCacheEntry<T> {
  final T data;
  final DateTime timestamp;
  ApiCacheEntry(this.data) : timestamp = DateTime.now();
}

class ApiCache {
  static final ApiCache _instance = ApiCache._();
  factory ApiCache() => _instance;
  ApiCache._();

  final _store = <String, ApiCacheEntry<dynamic>>{};
  static const defaultTtl = Duration(seconds: 30);

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > defaultTtl) {
      _store.remove(key);
      return null;
    }
    return entry.data as T;
  }

  void set<T>(String key, T data) {
    _store[key] = ApiCacheEntry<T>(data);
  }

  void remove(String key) {
    _store.remove(key);
  }

  void removePattern(String pattern) {
    _store.removeWhere((key, _) => key.contains(pattern));
  }

  void clear() {
    _store.clear();
  }
}
