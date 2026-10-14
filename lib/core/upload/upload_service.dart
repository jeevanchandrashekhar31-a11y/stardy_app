import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../logging/app_logger.dart';

final uploadServiceProvider = Provider<UploadService>((ref) {
  return UploadService(ref.watch(apiClientProvider));
});

class CancellationToken {
  bool isCancelled = false;
  void Function()? onCancel;

  void cancel() {
    isCancelled = true;
    onCancel?.call();
  }
}

class UploadService {
  final ApiClient _apiClient;
  static const _allowedExtensions = {'pdf', 'doc', 'docx', 'zip', 'png', 'jpg', 'jpeg'};

  UploadService(this._apiClient);

  Future<Result<String>> upload({
    required String purpose,
    String? targetId,
    required PlatformFile file,
    void Function(double)? onProgress,
    CancellationToken? cancelToken,
  }) async {
    // 1. Extension check
    final ext = file.extension?.toLowerCase();
    if (ext == null || !_allowedExtensions.contains(ext)) {
      return Err(const ValidationFailure('File type not allowed.'));
    }

    // 2. Presign
    final String contentType;
    if (ext == 'pdf') {
      contentType = 'application/pdf';
    } else if (ext == 'jpg' || ext == 'jpeg') {
      contentType = 'image/jpeg';
    } else if (ext == 'png') {
      contentType = 'image/png';
    } else {
      contentType = 'application/octet-stream';
    }

    final presignBody = <String, dynamic>{
      'purpose': purpose,
      'fileName': file.name,
      'sizeBytes': file.size,
      'contentType': contentType,
    };
    if (targetId != null) presignBody['targetId'] = targetId;

    final presignRes = await _apiClient.post<Map<String, dynamic>>(
      '/uploads/presign',
      body: presignBody,
    );

    if (presignRes is Err) {
      return Err((presignRes as Err).error);
    }
    
    final presignData = (presignRes as Ok<Map<String, dynamic>>).data;
    final uploadUrl = presignData['uploadUrl'] as String?;
    final objectKey = presignData['objectKey'] as String?;
    final maxBytes = presignData['maxBytes'] as int?;
    final method = presignData['method'] as String?;
    final headers = presignData['headers'] as Map<String, dynamic>?;

    if (uploadUrl == null || objectKey == null || maxBytes == null || method == null || headers == null) {
      return Err(const MalformedFailure('Missing presign details.'));
    }

    if (!uploadUrl.startsWith('https://')) {
      return Err(const ValidationFailure('Insecure upload URL rejected.'));
    }

    // 3. Size check against maxBytes
    if (file.size > maxBytes) {
      return Err(ValidationFailure('File exceeds max size of $maxBytes bytes.'));
    }

    if (cancelToken?.isCancelled == true) {
      return Err(const NetworkFailure('Upload cancelled'));
    }

    // 4. Stream upload
    final client = http.Client();
    DateTime lastChunkPulledAt = clock.now();
    String? abortReason;
    final abortCompleter = Completer<void>();

    void abort(String reason) {
      if (abortReason != null) return;
      abortReason = reason;
      if (!abortCompleter.isCompleted) {
        abortCompleter.complete();
      }
      client.close();
    }

    Timer? stallTimer;
    Timer? overallTimer;
    Timer? responseTimeoutTimer;

    try {
      final request = http.StreamedRequest(method, Uri.parse(uploadUrl));
      request.contentLength = file.size;
      for (final entry in headers.entries) {
        request.headers[entry.key] = entry.value.toString();
      }

      int bytesUploaded = 0;
      final baseStream = file.readStream ?? File(file.path!).openRead();
      final fileStream = baseStream.map((chunk) {
        lastChunkPulledAt = clock.now();
        bytesUploaded += chunk.length;
        if (onProgress != null && file.size > 0) {
          final p = bytesUploaded / file.size;
          onProgress(p >= 1.0 ? 0.99 : p);
        }
        return chunk;
      });

      cancelToken?.onCancel = () => abort('cancelled');

      stallTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (clock.now().difference(lastChunkPulledAt) > const Duration(seconds: 60)) {
          abort('stalled');
        }
      });

      overallTimer = Timer(const Duration(minutes: 10), () => abort('timeout'));

      final responseFuture = client.send(request);
      responseFuture.ignore();

      final bodyFuture = request.sink.addStream(fileStream).then((_) => request.sink.close());
      bodyFuture.ignore();

      await Future.any([bodyFuture, abortCompleter.future]);
      if (abortReason != null) {
        throw NetworkFailure('Upload aborted: $abortReason');
      }

      stallTimer.cancel();
      stallTimer = null;

      responseTimeoutTimer = Timer(const Duration(seconds: 30), () => abort('timeout'));

      final response = await Future.any([
        responseFuture,
        abortCompleter.future.then<http.StreamedResponse>((_) => throw NetworkFailure('Upload aborted: $abortReason')),
      ]);

      responseTimeoutTimer.cancel();
      responseTimeoutTimer = null;

      if (abortReason != null) {
        throw NetworkFailure('Upload aborted: $abortReason');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (onProgress != null) onProgress(1.0);
        return Ok(objectKey);
      } else {
        return Err(ServerFailure('Upload failed with status ${response.statusCode}'));
      }
    } catch (e) {
      AppLogger.error('UploadService', 'Upload failed');
      if (abortReason == 'cancelled') {
        return Err(const NetworkFailure('Upload cancelled'));
      } else if (abortReason == 'stalled') {
        return Err(const NetworkFailure('Upload stalled'));
      } else if (abortReason == 'timeout') {
        return Err(const NetworkFailure('Upload timeout'));
      }
      return Err(const NetworkFailure('Upload failed.'));
    } finally {
      stallTimer?.cancel();
      overallTimer?.cancel();
      responseTimeoutTimer?.cancel();
      client.close();
    }
  }
}
