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

  SseClient({
    required this.url,
    this.headers = const {},
    this.queryParams = const {},
  });

  Stream<Map<String, dynamic>> connect() {
    final controller = StreamController<Map<String, dynamic>>();

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
          buffer += data;
          while (buffer.contains('\n\n')) {
            final index = buffer.indexOf('\n\n');
            final event = buffer.substring(0, index);
            buffer = buffer.substring(index + 2);

            for (final line in event.split('\n')) {
              if (line.startsWith('data: ')) {
                final jsonStr = line.substring(6);
                try {
                  final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
                  controller.add(parsed);
                } catch (e) {
                  debugPrint('[SseClient] SSE parse error: $e');
                }
              }
            }
          }
        },
        onError: (error) {
          controller.addError(error);
        },
        onDone: () {
          controller.close();
        },
      );
    } catch (e) {
      controller.addError(e);
    }
  }

  void close() {
    _subscription?.cancel();
    _client?.close();
  }
}
