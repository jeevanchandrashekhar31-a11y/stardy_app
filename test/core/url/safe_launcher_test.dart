// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/url/safe_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockUrlLauncher extends UrlLauncherPlatform with MockPlatformInterfaceMixin {
  String? launchedUrl;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    return true;
  }

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrl = url;
    return true;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrl = url;
    return true;
  }
}

void main() {
  testWidgets('SafeLauncher tests: https allowed; http, javascript:, file:, intent:, mailto:, empty host all rejected', (tester) async {
    final mock = MockUrlLauncher();
    UrlLauncherPlatform.instance = mock;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  await SafeLauncher.launchSafe(context, 'https://example.com');
                  await SafeLauncher.launchSafe(context, 'http://example.com');
                  await SafeLauncher.launchSafe(context, 'javascript:alert(1)');
                  await SafeLauncher.launchSafe(context, 'file:///etc/passwd');
                  await SafeLauncher.launchSafe(context, 'intent://something');
                  await SafeLauncher.launchSafe(context, 'mailto:test@example.com');
                  await SafeLauncher.launchSafe(context, 'https://');
                },
                child: const Text('Launch'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Only the first one (https://example.com) should have been launched
    expect(mock.launchedUrl, 'https://example.com');
    // There should be SnackBars for the invalid URLs (6 of them)
    expect(find.text('Invalid or insecure URL'), findsWidgets);
  });
}
