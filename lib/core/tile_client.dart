import 'dart:async';

import 'package:http/http.dart' as http;

/// HTTP client for map tiles. A map view asks for dozens of tiles at once;
/// on Windows that many parallel connections often fail with
/// "semaphore timeout" (errno 121). This client
///  * keeps at most [maxParallel] requests in flight (the rest wait in a queue),
///  * gives every request a hard timeout,
///  * retries a failed request once.
/// It is shared by all tile layers and never closed.
class LimitedClient extends http.BaseClient {
  LimitedClient({int maxParallel = 6, this.timeout = const Duration(seconds: 10)})
      : _max = maxParallel,
        _inner = http.Client();

  final http.Client _inner;
  final int _max;
  final Duration timeout;
  int _active = 0;
  final List<Completer<void>> _queue = [];

  static final LimitedClient shared = LimitedClient();

  Future<void> _acquire() {
    if (_active < _max) {
      _active++;
      return Future.value();
    }
    final c = Completer<void>();
    _queue.add(c);
    return c.future;
  }

  void _release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete(); // the slot passes to the next request
    } else if (_active > 0) {
      _active--;
    }
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await _acquire();
    var released = false;
    void done() {
      if (released) return;
      released = true;
      _release();
    }

    try {
      Object? lastError;
      for (var attempt = 0; attempt < 2; attempt++) {
        try {
          final copy = http.Request(request.method, request.url)
            ..headers.addAll(request.headers)
            ..followRedirects = request.followRedirects
            ..maxRedirects = request.maxRedirects;
          final resp = await _inner.send(copy).timeout(timeout);
          if (resp.statusCode >= 500 && attempt == 0) {
            lastError = http.ClientException('HTTP ${resp.statusCode}', request.url);
            await Future<void>.delayed(const Duration(milliseconds: 400));
            continue;
          }
          // Free the slot when the body has been read (or after a safety timeout).
          final guard = Timer(const Duration(seconds: 25), done);
          final body = resp.stream.transform(StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (data, sink) => sink.add(data),
            handleError: (e, s, sink) => sink.addError(e, s),
            handleDone: (sink) {
              guard.cancel();
              done();
              sink.close();
            },
          ));
          return http.StreamedResponse(
            body,
            resp.statusCode,
            contentLength: resp.contentLength,
            request: resp.request,
            headers: resp.headers,
            isRedirect: resp.isRedirect,
            persistentConnection: resp.persistentConnection,
            reasonPhrase: resp.reasonPhrase,
          );
        } catch (e) {
          lastError = e;
          if (attempt == 0) await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
      done();
      throw lastError ?? http.ClientException('tile request failed', request.url);
    } catch (e) {
      done();
      rethrow;
    }
  }

  @override
  void close() {
    // shared instance: tile layers must not close it
  }
}
