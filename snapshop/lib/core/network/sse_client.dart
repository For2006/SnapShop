import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SseClient {
  final String url;
  final Map<String, String> headers;
  final Map<String, String> queryParams;
  HttpClient? _client;
  StreamSubscription? _subscription;
  bool _closed = false;

  SseClient({
    required this.url,
    this.headers = const {},
    this.queryParams = const {},
  });

  Stream<Map<String, dynamic>> connect() {
    final controller = StreamController<Map<String, dynamic>>(
      onCancel: () {
        close();
      },
    );

    _connect(controller);

    return controller.stream;
  }

  Future<void> _connect(StreamController<Map<String, dynamic>> controller) async {
    try {
      _client = HttpClient();
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final request = await _client!.getUrl(uri);

      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      String buffer = '';

      _subscription = response.transform(utf8.decoder).listen(
        (data) {
          if (_closed) return;
          buffer += data;
          if (buffer.length > 2 * 1024 * 1024) {
            final lastComplete = buffer.lastIndexOf('\n\n');
            if (lastComplete >= 0) {
              buffer = buffer.substring(lastComplete + 2);
            } else {
              buffer = '';
            }
            debugPrint('[SseClient] 缓冲区截断，保留尾部 ${buffer.length} 字节');
          }
          while (buffer.contains('\n\n')) {
            final index = buffer.indexOf('\n\n');
            final event = buffer.substring(0, index);
            buffer = buffer.substring(index + 2);

            for (final line in event.split('\n')) {
              if (line.startsWith('data: ')) {
                final jsonStr = line.substring(6);
                try {
                  final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
                  if (!_closed) {
                    controller.add(parsed);
                  }
                } catch (e) {
                  debugPrint('[SseClient] SSE parse error: $e');
                }
              }
            }
          }
        },
        onError: (error) {
          if (!_closed && !controller.isClosed) {
            controller.addError(error);
          }
          close();
        },
        onDone: () {
          if (!_closed && !controller.isClosed) {
            controller.close();
          }
          _closed = true;
        },
      );
    } catch (e) {
      if (!_closed && !controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
      _closed = true;
    }
  }

  void close() {
    if (_closed) return;
    _closed = true;
    _subscription?.cancel();
    _subscription = null;
    _client?.close();
    _client = null;
  }
}
