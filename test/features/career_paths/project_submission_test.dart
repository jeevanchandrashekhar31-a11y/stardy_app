import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stardy_app/Views/CareerPath/project_submission_page.dart';
import 'package:stardy_app/features/career_paths/repository/career_paths_repository.dart';
import 'package:stardy_app/core/upload/upload_service.dart';
import 'package:stardy_app/core/network/api_client.dart';

class FakeCareerPathsRepository extends CareerPathsRepository {
  final Future<Result<Map<String, dynamic>>> Function(String, String, {String? linkUrl, String? objectKey, String? fileName, int? sizeBytes}) onSubmitProject;

  FakeCareerPathsRepository({required this.onSubmitProject}) : super(ApiClient());

  @override
  Future<Result<Map<String, dynamic>>> submitProject(
    String projectId,
    String idempotencyKey, {
    String? linkUrl,
    String? objectKey,
    String? fileName,
    int? sizeBytes,
  }) => onSubmitProject(projectId, idempotencyKey, linkUrl: linkUrl, objectKey: objectKey, fileName: fileName, sizeBytes: sizeBytes);
}

class FakeUploadService extends UploadService {
  final Future<Result<String>> Function() onUpload;

  FakeUploadService({required this.onUpload}) : super(ApiClient());

  @override
  Future<Result<String>> upload({
    required String purpose,
    String? targetId,
    required PlatformFile file,
    void Function(double)? onProgress,
    CancellationToken? cancelToken,
  }) => onUpload();
}

class MockFilePicker extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 20,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return FilePickerResult([
      PlatformFile(
        name: 'test.pdf',
        size: 1024,
        path: '/test/path/test.pdf',
      )
    ]);
  }
}

void main() {
  setUpAll(() {
    FilePicker.platform = MockFilePicker();
  });

  Widget buildApp(CareerPathsRepository repo, UploadService uploadService) {
    return ProviderScope(
      overrides: [
        careerPathsRepositoryProvider.overrideWithValue(repo),
        uploadServiceProvider.overrideWithValue(uploadService),
      ],
      child: const MaterialApp(
        home: ProjectSubmissionPage(projectId: 'p1'),
      ),
    );
  }

  group('ProjectSubmissionPage UI', () {
    testWidgets('neither link nor file blocked', (tester) async {
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async => Ok({}),
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Attach a file or add a link before submitting'), findsOneWidget);
    });

    testWidgets('link validation: http rejected', (tester) async {
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async => Ok({}),
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'http://example.com');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Must be a valid https:// URL'), findsOneWidget);
    });

    testWidgets('link validation: javascript rejected', (tester) async {
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async => Ok({}),
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'javascript:alert(1)');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Must be a valid https:// URL'), findsOneWidget);
    });

    testWidgets('link validation: no host rejected', (tester) async {
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async => Ok({}),
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https:///path');
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Must be a valid https:// URL'), findsOneWidget);
    });

    testWidgets('link validation: 501 chars rejected', (tester) async {
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async => Ok({}),
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      final longStr = 'https://example.com/${"a" * 481}'; // 20 + 481 = 501
      await tester.enterText(find.byType(TextField), longStr);
      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Link must be 500 characters or less'), findsOneWidget);
    });

    testWidgets('link only successful submission', (tester) async {
      int calls = 0;
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async {
          calls++;
          expect(linkUrl, 'https://example.com');
          return Ok({'status': 'PENDING_REVIEW'});
        },
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://example.com');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('SUBMISSION RECEIVED'), findsOneWidget);
    });

    testWidgets('double-tap sends once', (tester) async {
      int calls = 0;
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async {
          calls++;
          await Future.delayed(const Duration(milliseconds: 100)); // Delay to allow double tap
          return Ok({'status': 'PENDING_REVIEW'});
        },
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://example.com');
      
      // Tap twice
      await tester.tap(find.text('Submit'));
      await tester.tap(find.text('Submit'));
      
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('SUBMISSION RECEIVED'), findsOneWidget);
    });

    testWidgets('409 on submit', (tester) async {
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async {
          return Err(const ConflictFailure('Already submitted'));
        },
      );
      final upload = FakeUploadService(onUpload: () async => Ok(''));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://example.com');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Already submitted'), findsOneWidget);
    });
    testWidgets('file only successful submission', (tester) async {
      int calls = 0;
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async {
          calls++;
          expect(linkUrl, null);
          expect(objectKey, 'obj-123');
          expect(fileName, 'test.pdf');
          expect(sizeBytes, 1024);
          return Ok({'status': 'PENDING_REVIEW'});
        },
      );
      final upload = FakeUploadService(onUpload: () async => Ok('obj-123'));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.tap(find.text('( Drop or browse your files )'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('SUBMISSION RECEIVED'), findsOneWidget);
    });

    testWidgets('both link and file successful submission', (tester) async {
      int calls = 0;
      final repo = FakeCareerPathsRepository(
        onSubmitProject: (pId, k, {linkUrl, objectKey, fileName, sizeBytes}) async {
          calls++;
          expect(linkUrl, 'https://example.com');
          expect(objectKey, 'obj-123');
          expect(fileName, 'test.pdf');
          expect(sizeBytes, 1024);
          return Ok({'status': 'PENDING_REVIEW'});
        },
      );
      final upload = FakeUploadService(onUpload: () async => Ok('obj-123'));

      await tester.pumpWidget(buildApp(repo, upload));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'https://example.com');
      await tester.tap(find.text('( Drop or browse your files )'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('SUBMISSION RECEIVED'), findsOneWidget);
    });
  });
}
