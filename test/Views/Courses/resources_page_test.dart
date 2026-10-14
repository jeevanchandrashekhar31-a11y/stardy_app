import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/Views/Courses/Course_SUB_Pages/resources_page.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';
import 'package:stardy_app/features/courses/models/course_enums.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockUrlLauncher extends Fake with MockPlatformInterfaceMixin implements UrlLauncherPlatform {
  String? launchedUrl;

  @override
  Future<bool> canLaunch(String url) async {
    return true; // We always allow launch if it reaches here
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    return true;
  }
}

void main() {
  group('ResourcesPage Tests', () {
    late MockUrlLauncher mockLauncher;

    setUp(() {
      mockLauncher = MockUrlLauncher();
      UrlLauncherPlatform.instance = mockLauncher;
    });

    testWidgets('renders empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesProvider('c1').overrideWith((ref) => []),
          ],
          child: const MaterialApp(
            home: ResourcesPage(courseId: 'c1'),
          ),
        ),
      );

      expect(find.text('No resources available.'), findsOneWidget);
    });

    testWidgets('renders links and files, tapping https link launches, non-https does not', (tester) async {
      final resources = [
        ResourceItem(
          id: 'r1',
          title: 'Valid Https Link',
          type: ResourceType.link,
          url: 'https://example.com',
        ),
        ResourceItem(
          id: 'r2',
          title: 'Invalid Http Link',
          type: ResourceType.link,
          url: 'http://example.com', // Not https
        ),
        ResourceItem(
          id: 'r3',
          title: 'File Resource',
          type: ResourceType.file,
          url: 'https://file.com',
        ),
        ResourceItem(
          id: 'r4',
          title: 'Malicious Link',
          type: ResourceType.link,
          url: 'javascript:alert(1)', // Not https
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resourcesProvider('c1').overrideWith((ref) => resources),
          ],
          child: const MaterialApp(
            home: ResourcesPage(courseId: 'c1'),
          ),
        ),
      );

      expect(find.text('Valid Https Link'), findsOneWidget);
      expect(find.text('Invalid Http Link'), findsOneWidget);
      expect(find.text('File Resource'), findsOneWidget);

      // Tap valid https link
      await tester.tap(find.text('Valid Https Link'));
      await tester.pumpAndSettle();
      expect(mockLauncher.launchedUrl, 'https://example.com');
      
      mockLauncher.launchedUrl = null;

      // Tap invalid http link
      await tester.tap(find.text('Invalid Http Link'));
      await tester.pumpAndSettle();
      expect(mockLauncher.launchedUrl, isNull);

      // Tap valid file resource (https)
      await tester.tap(find.text('File Resource'));
      await tester.pumpAndSettle();
      expect(mockLauncher.launchedUrl, 'https://file.com');

      mockLauncher.launchedUrl = null;

      // Tap malicious link
      await tester.tap(find.text('Malicious Link'));
      await tester.pumpAndSettle();
      expect(mockLauncher.launchedUrl, isNull);
    });
  });
}
