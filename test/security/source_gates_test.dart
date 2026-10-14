import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Source code gates - security and quality checks', () {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue, reason: 'lib directory must exist');

    final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

    final failures = <String>[];

    // Banned keywords across all Dart files in lib/
    final forbiddenExact = [
      'print(',
      'debugPrint(',
      'http://',
      'badCertificateCallback',
      'withData: true',
      'UniqueKey().toString',
      'Provider<dynamic>',
      'invalidateSelf',
      'firestore',
      'cloud_firestore',
      'firebase_storage',
      'storage_service',
      'level + 1',
      'xpEarned =',
      'api.example.com',
      'BRIDGE(',
      'youtube',
    ];

    final exceptionToStringRegex = RegExp(
      r'(error:\s*|state\s*=.*|Text\(\s*|SnackBar\(\s*)(e|err|error|ex)\.toString\(\)',
    );

    // Hardcoded Bearer token literal (e.g. 'Bearer ey...' or 'Bearer my-token' without interpolation '$')
    final hardcodedBearerRegex = RegExp(
      r'''['"]Bearer\s+(?!\[REDACTED\])[^$\r\n'"]+['"]''',
      caseSensitive: false,
    );

    for (final file in files) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final lines = file.readAsLinesSync();

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        if (trimmed.startsWith('//')) continue;

        // launchUrl gate: only permitted inside lib/core/url/safe_launcher.dart
        if (trimmed.contains('launchUrl(')) {
          if (!normalizedPath.contains('lib/core/url/safe_launcher.dart')) {
            final commentIdx = line.indexOf('//');
            final forbiddenIdx = line.indexOf('launchUrl(');
            if (commentIdx == -1 || commentIdx > forbiddenIdx) {
              failures.add(
                '${file.path}:${i + 1}: contains forbidden string "launchUrl(" outside safe_launcher.dart',
              );
            }
          }
        }

        // correctIndex gate: only permitted in remedial feature and remedial page
        if (line.contains('correctIndex')) {
          final isAllowedRemedial = normalizedPath.contains('lib/features/remedial/') ||
              normalizedPath.contains('remedial_quiz_page.dart');
          if (!isAllowedRemedial) {
            final commentIdx = line.indexOf('//');
            final forbiddenIdx = line.indexOf('correctIndex');
            if (commentIdx == -1 || commentIdx > forbiddenIdx) {
              failures.add(
                '${file.path}:${i + 1}: contains "correctIndex" outside lib/features/remedial/ and remedial page',
              );
            }
          }
        }

        // StarbuddyScreen gate: any reference to StarbuddyScreen outside lib/Views/starbuddy/ and the flag check fails
        if (line.contains('StarbuddyScreen')) {
          final isInsideStarbuddyDir = normalizedPath.contains('lib/Views/starbuddy/');
          if (!isInsideStarbuddyDir) {
            final fileContent = file.readAsStringSync();
            final checksFlag = fileContent.contains('FeatureFlags.starbuddy');
            if (!checksFlag) {
              failures.add(
                '${file.path}:${i + 1}: references StarbuddyScreen outside lib/Views/starbuddy/ without checking FeatureFlags.starbuddy',
              );
            }
          }
        }

        // SharedPreferences used for auth or onboarding state gate
        if (line.contains('SharedPreferences')) {
          final isAuthOrOnboardingFile = normalizedPath.contains('/auth/') ||
              normalizedPath.contains('/onboarding/');
          final mentionsAuthOrOnboarding = line.toLowerCase().contains('auth') ||
              line.toLowerCase().contains('onboard') ||
              line.toLowerCase().contains('token');
          if (isAuthOrOnboardingFile || mentionsAuthOrOnboarding) {
            final commentIdx = line.indexOf('//');
            final forbiddenIdx = line.indexOf('SharedPreferences');
            if (commentIdx == -1 || commentIdx > forbiddenIdx) {
              failures.add(
                '${file.path}:${i + 1}: SharedPreferences used for auth or onboarding state',
              );
            }
          }
        }

        // Hardcoded Bearer token gate
        if (!line.contains("r'Bearer") && !line.contains('r"Bearer')) {
          final bearerMatch = hardcodedBearerRegex.firstMatch(line);
          if (bearerMatch != null) {
            final commentIdx = line.indexOf('//');
            if (commentIdx == -1 || commentIdx > bearerMatch.start) {
              failures.add(
                '${file.path}:${i + 1}: contains hardcoded Bearer token: ${bearerMatch.group(0)}',
              );
            }
          }
        }

        // Forbidden exact strings
        for (final forbidden in forbiddenExact) {
          if (line.contains(forbidden)) {
            final commentIdx = line.indexOf('//');
            final forbiddenIdx = line.indexOf(forbidden);
            if (commentIdx != -1 && commentIdx < forbiddenIdx) continue;

            failures.add('${file.path}:${i + 1}: contains forbidden string "$forbidden"');
          }
        }

        // Exception .toString() directly in state or UI
        if (exceptionToStringRegex.hasMatch(line)) {
          final commentIdx = line.indexOf('//');
          final match = exceptionToStringRegex.firstMatch(line)!;
          if (commentIdx == -1 || commentIdx > match.start) {
            failures.add('${file.path}:${i + 1}: caught exception .toString() used directly in state or UI');
          }
        }
      }
    }

    // pubspec.yaml gate: firestore / cloud_firestore / firebase_storage / storage_service
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final pubspecContent = pubspecFile.readAsStringSync();
      final pubspecBanned = [
        'firestore',
        'cloud_firestore',
        'firebase_storage',
        'storage_service',
      ];
      for (final banned in pubspecBanned) {
        if (pubspecContent.contains(banned)) {
          failures.add('pubspec.yaml: contains forbidden dependency/reference "$banned"');
        }
      }
    }

    if (failures.isNotEmpty) {
      fail('Source gate failures found:\n${failures.join('\n')}');
    }
  });

  test('Platform configuration gates - Android Manifest and iOS Info.plist', () {
    // 1. Android Main Manifest checks
    final mainManifest = File('android/app/src/main/AndroidManifest.xml');
    expect(mainManifest.existsSync(), isTrue, reason: 'android/app/src/main/AndroidManifest.xml must exist');
    final mainContent = mainManifest.readAsStringSync();

    expect(
      mainContent.contains('android:usesCleartextTraffic="false"'),
      isTrue,
      reason: 'android:usesCleartextTraffic="false" must be explicitly set in main manifest',
    );
    expect(
      mainContent.contains('android:usesCleartextTraffic="true"'),
      isFalse,
      reason: 'android:usesCleartextTraffic="true" must NOT be in main manifest',
    );
    expect(
      mainContent.contains('tools:replace="android:usesCleartextTraffic"'),
      isFalse,
      reason: 'Cleartext override must NOT exist in main manifest',
    );
    expect(
      mainContent.contains('android:allowBackup="false"'),
      isTrue,
      reason: 'android:allowBackup="false" must be explicitly set',
    );
    expect(
      mainContent.contains('android:debuggable'),
      isFalse,
      reason: 'android/app/src/main/AndroidManifest.xml must not contain android:debuggable flag',
    );

    // 2. Android Debug Manifest override check: exists only under android/app/src/debug/
    final debugManifest = File('android/app/src/debug/AndroidManifest.xml');
    expect(debugManifest.existsSync(), isTrue, reason: 'android/app/src/debug/AndroidManifest.xml must exist');
    final debugContent = debugManifest.readAsStringSync();
    expect(
      debugContent.contains('android:usesCleartextTraffic="true"'),
      isTrue,
      reason: 'debug AndroidManifest.xml must set android:usesCleartextTraffic="true"',
    );
    expect(
      debugContent.contains('tools:replace="android:usesCleartextTraffic"'),
      isTrue,
      reason: 'debug AndroidManifest.xml must specify tools:replace="android:usesCleartextTraffic"',
    );

    // 3. Verify NO such override exists in src/main, src/profile, or src/release
    for (final variant in ['main', 'profile', 'release']) {
      final variantManifest = File('android/app/src/$variant/AndroidManifest.xml');
      if (variantManifest.existsSync()) {
        final content = variantManifest.readAsStringSync();
        expect(
          content.contains('android:usesCleartextTraffic="true"') ||
              content.contains('tools:replace="android:usesCleartextTraffic"'),
          isFalse,
          reason: 'No cleartext override permitted in android/app/src/$variant/AndroidManifest.xml',
        );
      }
    }

    // 4. iOS Info.plist checks
    final plistFile = File('ios/Runner/Info.plist');
    expect(plistFile.existsSync(), isTrue, reason: 'ios/Runner/Info.plist must exist');
    final plistContent = plistFile.readAsStringSync();

    expect(
      plistContent.contains('NSAllowsArbitraryLoads'),
      isFalse,
      reason: 'NSAllowsArbitraryLoads must be absent in ios/Runner/Info.plist',
    );
  });
}
