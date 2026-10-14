import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/core/upload/upload_service.dart';

class _FakeApiClient extends ApiClient {
  final Future<Result<dynamic>> Function(String method, String path, Map<String, dynamic>? body, String? idempotencyKey) handler;
  _FakeApiClient(this.handler);

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

class _FakeHttpClientOverrides extends HttpOverrides {
  final Future<HttpClientResponse> Function(HttpClientRequest request) onPut;
  _FakeHttpClientOverrides(this.onPut);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(onPut);
  }
}

class _FakeHttpClient implements HttpClient {
  final Future<HttpClientResponse> Function(HttpClientRequest request) onPut;
  _FakeHttpClient(this.onPut);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (method == 'PUT') {
      return _FakeHttpRequest(onPut);
    }
    throw UnimplementedError('Method $method not implemented');
  }
}

class _FakeHttpRequest implements HttpClientRequest {
  final Future<HttpClientResponse> Function(HttpClientRequest request) onPut;
  final List<List<int>> bodyBytes = [];

  _FakeHttpRequest(this.onPut);

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
  set contentLength(int length) {}

  @override
  void add(List<int> data) {
    bodyBytes.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final completer = Completer<void>();
    stream.listen(
      (chunk) => add(chunk),
      onError: (e, st) {
        if (!completer.isCompleted) completer.completeError(e, st);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  @override
  Future<HttpClientResponse> close() async {
    return onPut(this);
  }
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
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    onDone?.call();
    return const Stream<List<int>>.empty().listen(onData);
  }
}

void main() {
  group('UploadService contract & upload tests (FAKE-SERVER)', () {
    late File tempFile;

    setUpAll(() {
      tempFile = File('test_upload_contract.zip');
      tempFile.writeAsBytesSync(List.filled(128, 0));
    });

    tearDownAll(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
      HttpOverrides.global = null;
    });

    test('upload parses presign.json fixture and executes streamed upload', () async {
      final fixtureFile = File('test/fixtures/contract/presign.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      final presignData = fixtureJson['data'] as Map<String, dynamic>;

      int presignCalls = 0;
      int putCalls = 0;

      final fakeApi = _FakeApiClient((method, path, body, idemp) async {
        if (path == '/uploads/presign') {
          presignCalls++;
          return Ok(presignData);
        }
        return Err(const ServerFailure('Not found'));
      });

      HttpOverrides.global = _FakeHttpClientOverrides((req) async {
        putCalls++;
        return _FakeHttpResponse(200);
      });

      final uploadService = UploadService(fakeApi);
      final platformFile = PlatformFile(
        name: 'test_upload_contract.zip',
        size: tempFile.lengthSync(),
        path: tempFile.path,
      );

      final result = await uploadService.upload(
        purpose: 'ASSIGNMENT_FILE',
        targetId: 'asg_01',
        file: platformFile,
      );

      expect(result is Ok<String>, isTrue);
      expect((result as Ok<String>).data, presignData['objectKey']);
      expect(presignCalls, 1);
      expect(putCalls, 1);
    });

    test('upload rejects disallowed file extension without calling presign', () async {
      final fakeApi = _FakeApiClient((method, path, body, idemp) async {
        fail('Presign should not be called');
      });

      final uploadService = UploadService(fakeApi);
      final platformFile = PlatformFile(
        name: 'script.exe',
        size: 100,
        bytes: null,
        path: 'dummy/path/script.exe',
      );

      final result = await uploadService.upload(
        purpose: 'ASSIGNMENT_FILE',
        file: platformFile,
      );

      expect(result is Err, isTrue);
      expect((result as Err).error is ValidationFailure, isTrue);
    });
  });
}
