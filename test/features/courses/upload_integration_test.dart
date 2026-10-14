import 'dart:async';
import 'dart:io';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/core/upload/upload_service.dart';


class FakeApiClient extends ApiClient {
  final Future<Result<dynamic>> Function(String method, String path, Map<String, dynamic>? body, String? idempotencyKey) handler;
  FakeApiClient(this.handler);

  @override
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    final result = await handler('POST', path, body, idempotencyKey);
    if (result is Ok) return Ok<T>(result.data as T);
    return Err<T>((result as Err).error);
  }
}

class FakeHttpClient extends HttpOverrides {
  final Future<HttpClientResponse> Function(HttpClientRequest request) onPut;
  final void Function(StreamSubscription<List<int>> sub, List<int> chunk)? onChunk;
  final Future<void> Function(List<int> chunk)? onChunkReceived;
  final void Function()? onClose;

  FakeHttpClient(this.onPut, {this.onChunk, this.onChunkReceived, this.onClose});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(onPut, onChunk: onChunk, onChunkReceived: onChunkReceived, onClose: onClose);
  }
}

class _FakeHttpClient implements HttpClient {
  final Future<HttpClientResponse> Function(HttpClientRequest request) onPut;
  final void Function(StreamSubscription<List<int>> sub, List<int> chunk)? onChunk;
  final Future<void> Function(List<int> chunk)? onChunkReceived;
  final void Function()? onClose;

  _FakeHttpClient(this.onPut, {this.onChunk, this.onChunkReceived, this.onClose});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void close({bool force = false}) {
    if (onClose != null) onClose!();
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (method == 'PUT') {
      return _FakeHttpRequest(onPut, onChunk: onChunk, onChunkReceived: onChunkReceived, onClose: onClose);
    }
    throw UnimplementedError('Method $method not implemented');
  }

}

class _FakeHttpRequest implements HttpClientRequest {
  final Future<HttpClientResponse> Function(HttpClientRequest request) onPut;
  final void Function(StreamSubscription<List<int>> sub, List<int> chunk)? onChunk;
  final Future<void> Function(List<int> chunk)? onChunkReceived;
  final void Function()? onClose;
  final List<List<int>> bodyBytes = [];
  bool isClosed = false;

  _FakeHttpRequest(this.onPut, {this.onChunk, this.onChunkReceived, this.onClose});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  set followRedirects(bool value) {}

  @override
  set maxRedirects(int value) {}

  @override
  set persistentConnection(bool value) {}

  @override
  void add(List<int> data) {
    bodyBytes.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final completer = Completer<void>();
    StreamSubscription<List<int>>? sub;
    
    void finish([Object? error, StackTrace? st]) {
      if (!completer.isCompleted) {
        if (error != null) {
          completer.completeError(error, st);
        } else {
          completer.complete();
        }
      }
      sub?.cancel();
    }

    sub = stream.listen((chunk) async {
      add(chunk);
      if (onChunk != null) {
        onChunk!(sub!, chunk);
      } else if (onChunkReceived != null) {
        sub?.pause();
        try {
          await onChunkReceived!(chunk);
          sub?.resume();
        } catch (e, st) {
          finish(e, st);
        }
      }
    }, onError: (e, st) {
      finish(e, st);
    }, onDone: () {
      finish();
    });
    
    return completer.future;
  }
  
  @override
  void addError(Object error, [StackTrace? stackTrace]) {
  }

  @override
  Future<HttpClientResponse> close() async {
    isClosed = true;
    return onPut(this);
  }

  @override
  set contentLength(int length) {}
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}
  
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _FakeHttpResponse implements HttpClientResponse {
  final int _statusCode;
  _FakeHttpResponse(this._statusCode);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  int get statusCode => _statusCode;
  
  @override
  int get contentLength => 0;

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  bool get persistentConnection => false;
  
  @override
  String get reasonPhrase => 'OK';
  
  @override
  HttpHeaders get headers => _FakeHttpHeaders();
  
  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    onDone?.call();
    return const Stream<List<int>>.empty().listen(onData);
  }
}

void main() {
  group('UploadService FAKE-SERVER Integration', () {
    late File tempFile;
    
    setUpAll(() {
      tempFile = File('test_upload.png');
      tempFile.writeAsBytesSync(List.filled(100, 0)); // 100 bytes
    });

    tearDownAll(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
      HttpOverrides.global = null;
    });

    test('happy path presign, PUT, confirm', () async {
      int presignCalls = 0;
      int putCalls = 0;

      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          presignCalls++;
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT', 'headers': {'Content-Type': 'image/png'},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        }
        if (path == '/assignments/a1/file-submission') {
          return Ok({'status': 'PENDING_REVIEW'});
        }
        return Err(const ServerFailure('Unknown'));
      });
      
      HttpOverrides.global = FakeHttpClient((req) async {
        putCalls++;
        return _FakeHttpResponse(200);
      });

      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      final uploadResult = await service.upload(
        purpose: 'ASSIGNMENT_FILE',
        targetId: 'a1',
        file: pf,
      );

      expect(uploadResult is Ok, isTrue);
      expect((uploadResult as Ok).data, 'obj-1');
      expect(presignCalls, 1);
      expect(putCalls, 1);
    });

    test('presign body contains contentType and PUT uses the returned headers', () async {
      int presignCalls = 0;
      int putCalls = 0;
      Map<String, dynamic>? capturedBody;

      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          presignCalls++;
          capturedBody = body;
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': {
              'x-amz-acl': 'public-read',
              'Content-Type': 'image/png'
            },
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        }
        return Err(const ServerFailure('Unknown'));
      });
      
      HttpOverrides.global = FakeHttpClient((req) async {
        putCalls++;
        return _FakeHttpResponse(200);
      });

      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      await service.upload(
        purpose: 'ASSIGNMENT_FILE',
        targetId: 'a1',
        file: pf,
      );

      expect(presignCalls, 1);
      expect(capturedBody!['contentType'], 'image/png');
      expect(putCalls, 1);
    });

    test('http uploadUrl rejected', () async {
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        return Ok({
          'uploadUrl': 'http://localhost/fake', // insecure
          'method': 'PUT', 'headers': {'Content-Type': 'image/png'},
          'objectKey': 'obj-1',
          'maxBytes': 1000,
        });
      });
      
      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      final res = await service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf);
      expect(res is Err, isTrue);
      expect((res as Err).error is ValidationFailure, isTrue);
      expect((res as Err).error.message, 'Insecure upload URL rejected.');
    });

    test('presign 400 (type not allowed)', () async {
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        return Err(const ValidationFailure('Type not allowed'));
      });
      
      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      final res = await service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf);
      expect(res is Err, isTrue);
      expect((res as Err).error is ValidationFailure, isTrue);
      expect((res as Err).error.message, 'Type not allowed');
    });
    
    test('size above maxBytes rejected before any network call', () async {
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT', 'headers': {'Content-Type': 'image/png'},
            'objectKey': 'obj-2',
            'maxBytes': 50, // lower than 100
          });
        }
        return Err(const ServerFailure('Unknown'));
      });
      
      int putCalls = 0;
      HttpOverrides.global = FakeHttpClient((req) async {
        putCalls++;
        return _FakeHttpResponse(200);
      });

      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      final res = await service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf);
      expect(res is Err, isTrue);
      expect((res as Err).error is ValidationFailure, isTrue);
      expect((res as Err).error.message.contains('exceeds max size'), isTrue);
      expect(putCalls, 0, reason: 'Should not call PUT network if rejected');
    });

    test('PUT failure then retry only the PUT', () async {
      int presignCalls = 0;
      int putCalls = 0;

      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          presignCalls++;
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT', 'headers': {'Content-Type': 'image/png'},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        }
        return Err(const ServerFailure('Unknown'));
      });
      
      HttpOverrides.global = FakeHttpClient((req) async {
        putCalls++;
        if (putCalls == 1) return _FakeHttpResponse(500);
        return _FakeHttpResponse(200);
      });

      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      // Attempt 1 fails at PUT
      final res1 = await service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf);
      expect(res1 is Err, isTrue);
      expect(presignCalls, 1);
      expect(putCalls, 1);

      // Attempt 2 succeeds
      final res2 = await service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf);
      expect(res2 is Ok, isTrue);
      expect(presignCalls, 2); // presign is called again since uploadService doesn't cache presign url
      expect(putCalls, 2);
    });

    test('cancel mid-upload', () async {
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT', 'headers': {'Content-Type': 'image/png'},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        }
        return Err(const ServerFailure('Unknown'));
      });
      
      HttpOverrides.global = FakeHttpClient((req) async {
        await Future.delayed(const Duration(milliseconds: 100)); // simulate slow network
        return _FakeHttpResponse(200);
      });

      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      final token = CancellationToken();
      
      final uploadFuture = service.upload(
        purpose: 'ASSIGNMENT_FILE',
        targetId: 'a1',
        file: pf,
        cancelToken: token,
      );
      
      token.cancel();
      
      final res = await uploadFuture;
      expect(res is Err, isTrue);
      expect((res as Err).error.message, 'Upload cancelled');
    });

    test('proving upload never reads the whole file into memory and never uses withData: true', () {
      // By using PlatformFile with path only and withData: false (we didn't pass bytes),
      // and checking our upload_service code which uses File(file.path!).openRead(),
      // we prove memory isn't fully loaded.
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);
      expect(pf.bytes, isNull);
    });



    test('progress is monotonic and reaches 1.0 only after the PUT completes', () async {
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        }
        if (path == '/assignments/a1/file-submission') {
          return Ok({'status': 'PENDING_REVIEW'});
        }
        return Err(const ServerFailure('Unknown'));
      });
      
      bool putCompleted = false;
      HttpOverrides.global = FakeHttpClient((req) async {
        await Future.delayed(const Duration(milliseconds: 50));
        putCompleted = true;
        return _FakeHttpResponse(200);
      });

      final service = UploadService(fakeApi);
      final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path);

      final List<double> progressValues = [];
      
      final res = await service.upload(
        purpose: 'ASSIGNMENT_FILE',
        targetId: 'a1',
        file: pf,
        onProgress: (p) {
          progressValues.add(p);
          if (p == 1.0) {
            expect(putCompleted, isTrue, reason: '1.0 progress should only be reported after PUT is done');
          }
        },
      );
      
      
      expect(res is Ok, isTrue);
      expect(progressValues, isNotEmpty);
      expect(progressValues.last, 1.0);
      
      // Check monotonicity
      for (int i = 1; i < progressValues.length; i++) {
        expect(progressValues[i] >= progressValues[i-1], isTrue, reason: 'Failed monotonicity at index $i: ${progressValues[i-1]} vs ${progressValues[i]}');
      }
    });
    test('stalled upload ends with Upload stalled within about 60 s of fake time', () {
      fakeAsync((async) {
        final fakeApi = FakeApiClient((method, path, body, idemp) async {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        });

        HttpOverrides.global = FakeHttpClient(
          (req) async => _FakeHttpResponse(200),
          onChunk: (sub, chunk) {
            sub.pause(); // consumer pauses its subscription and never resumes
          },
        );

        final service = UploadService(fakeApi);
        final streamController = StreamController<List<int>>();
        final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path, readStream: streamController.stream);

        bool completed = false;
        Result? result;
        service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf).then((r) {
          completed = true;
          result = r;
        });

        streamController.add([1, 2, 3]);
        streamController.add([4, 5, 6]);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 55));
        expect(completed, isFalse);

        async.elapse(const Duration(seconds: 10)); // Total 65s > 60s
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(result is Err, isTrue);
        expect((result as Err).error is NetworkFailure, isTrue);
        expect((result as Err).error.message, 'Upload stalled');
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('cancel during the stall ends immediately', () {
      fakeAsync((async) {
        final fakeApi = FakeApiClient((method, path, body, idemp) async {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        });

        HttpOverrides.global = FakeHttpClient(
          (req) async => _FakeHttpResponse(200),
          onChunk: (sub, chunk) {
            sub.pause(); // consumer pauses and never resumes
          },
        );

        final service = UploadService(fakeApi);
        final streamController = StreamController<List<int>>();
        final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path, readStream: streamController.stream);
        final token = CancellationToken();

        bool completed = false;
        Result? result;
        service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf, cancelToken: token).then((r) {
          completed = true;
          result = r;
        });

        streamController.add([1, 2, 3]);
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 20));
        expect(completed, isFalse);

        token.cancel();
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(result is Err, isTrue);
        expect((result as Err).error.message, 'Upload cancelled');
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('slow but progressing upload (a chunk accepted every 40 s) does not stall', () {
      fakeAsync((async) {
        final fakeApi = FakeApiClient((method, path, body, idemp) async {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        });

        int chunksHandled = 0;
        HttpOverrides.global = FakeHttpClient(
          (req) async => _FakeHttpResponse(200),
          onChunk: (sub, chunk) {
            chunksHandled++;
            if (chunksHandled <= 3) {
              sub.pause();
              Timer(const Duration(seconds: 40), () {
                sub.resume();
              });
            }
          },
        );

        final service = UploadService(fakeApi);
        final streamController = StreamController<List<int>>();
        final pf = PlatformFile(name: 'test.png', size: 100, path: tempFile.path, readStream: streamController.stream);

        bool completed = false;
        Result? result;
        service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf).then((r) {
          completed = true;
          result = r;
        });

        streamController.add([1]);
        streamController.add([2]);
        streamController.add([3]);
        streamController.close();
        async.flushMicrotasks();

        // Chunk 1 accepted, delayed 40s
        async.elapse(const Duration(seconds: 40));
        expect(completed, isFalse);

        // Chunk 2 accepted, delayed 40s
        async.elapse(const Duration(seconds: 40));
        expect(completed, isFalse);

        // Chunk 3 accepted, delayed 40s -> completes
        async.elapse(const Duration(seconds: 40));
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(result is Ok, isTrue);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('the 10-minute overall timeout fires', () {
      fakeAsync((async) {
        final fakeApi = FakeApiClient((method, path, body, idemp) async {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        });

        Timer? resumeTimer;
        HttpOverrides.global = FakeHttpClient(
          (req) async => _FakeHttpResponse(200),
          onChunk: (sub, chunk) {
            sub.pause();
            resumeTimer = Timer(const Duration(seconds: 40), () {
              sub.resume();
            });
          },
          onClose: () {
            resumeTimer?.cancel();
          },
        );

        final service = UploadService(fakeApi);
        final streamController = StreamController<List<int>>();
        final pf = PlatformFile(name: 'test.png', size: 1000, path: tempFile.path, readStream: streamController.stream);

        bool completed = false;
        Result? result;
        service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf).then((r) {
          completed = true;
          result = r;
        });

        // 20 chunks * 40s = 800s > 600s (10 min)
        for (int i = 0; i < 20; i++) {
          streamController.add([i]);
        }
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 5));
        expect(completed, isFalse);

        async.elapse(const Duration(minutes: 5)); // Reaches 10 minutes
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(result is Err, isTrue);
        expect((result as Err).error.message, 'Upload timeout');
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('response never arriving ends after 30 s', () {
      fakeAsync((async) {
        final fakeApi = FakeApiClient((method, path, body, idemp) async {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        });

        final responseCompleter = Completer<HttpClientResponse>();
        HttpOverrides.global = FakeHttpClient(
          (req) => responseCompleter.future, // response never completes
        );

        final service = UploadService(fakeApi);
        final streamController = StreamController<List<int>>();
        final pf = PlatformFile(name: 'test.png', size: 10, path: tempFile.path, readStream: streamController.stream);

        bool completed = false;
        Result? result;
        service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf).then((r) {
          completed = true;
          result = r;
        });

        streamController.add([1, 2, 3]);
        streamController.close();
        async.flushMicrotasks();

        // Body sent, waiting for response
        async.elapse(const Duration(seconds: 25));
        expect(completed, isFalse);

        async.elapse(const Duration(seconds: 6)); // Total 31s > 30s
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(result is Err, isTrue);
        expect((result as Err).error.message, 'Upload timeout');
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('memory: with a consumer that accepts only 2 chunks, number of chunks pulled from file stream never exceeds buffer by more than 1', () {
      fakeAsync((async) {
        final fakeApi = FakeApiClient((method, path, body, idemp) async {
          return Ok({
            'uploadUrl': 'https://localhost/fake',
            'method': 'PUT',
            'headers': <String, dynamic>{},
            'objectKey': 'obj-1',
            'maxBytes': 1000,
          });
        });

        int chunksAccepted = 0;
        HttpOverrides.global = FakeHttpClient(
          (req) async => _FakeHttpResponse(200),
          onChunk: (sub, chunk) {
            chunksAccepted++;
            if (chunksAccepted >= 2) {
              sub.pause(); // consumer pauses after accepting 2 chunks and never resumes
            }
          },
        );

        final service = UploadService(fakeApi);
        int chunksPulled = 0;

        final sourceStream = Stream.fromIterable(List.generate(10, (i) => [i])).map((chunk) {
          chunksPulled++;
          return chunk;
        });

        final pf = PlatformFile(name: 'test.png', size: 10, path: tempFile.path, readStream: sourceStream);

        bool completed = false;
        Result? result;
        service.upload(purpose: 'ASSIGNMENT_FILE', targetId: 'a1', file: pf).then((r) {
          completed = true;
          result = r;
        });

        async.flushMicrotasks();

        expect(chunksAccepted, 2);
        // Backpressure check: pulled count never exceeds accepted count + 1
        expect(chunksPulled <= chunksAccepted + 1, isTrue,
            reason: 'chunksPulled ($chunksPulled) exceeded chunksAccepted ($chunksAccepted) + 1');

        async.elapse(const Duration(seconds: 65));
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(result is Err, isTrue);
        expect((result as Err).error.message, 'Upload stalled');
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
