import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App ID and Bundle Identifier Guard Tests', () {
    test('android/app/build.gradle.kts has applicationId com.stardyai.app and no com.example', () {
      final file = File('android/app/build.gradle.kts');
      expect(file.existsSync(), isTrue, reason: 'android/app/build.gradle.kts must exist');
      final content = file.readAsStringSync();

      expect(content.contains('com.example'), isFalse,
          reason: 'android/app/build.gradle.kts must not contain com.example');
      
      final appIdMatch = RegExp(r'applicationId\s*=\s*"([^"]+)"').firstMatch(content);
      expect(appIdMatch, isNotNull, reason: 'build.gradle.kts must declare applicationId');
      expect(appIdMatch!.group(1), equals('com.stardyai.app'),
          reason: 'Android applicationId must equal com.stardyai.app');

      final namespaceMatch = RegExp(r'namespace\s*=\s*"([^"]+)"').firstMatch(content);
      expect(namespaceMatch, isNotNull, reason: 'build.gradle.kts must declare namespace');
      expect(namespaceMatch!.group(1), equals('com.stardyai.app'),
          reason: 'Android namespace must equal com.stardyai.app');
    });

    test('android/app/src/*/AndroidManifest.xml files do not contain com.example', () {
      final srcDir = Directory('android/app/src');
      expect(srcDir.existsSync(), isTrue, reason: 'android/app/src must exist');

      final manifests = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.replaceAll('\\', '/').endsWith('AndroidManifest.xml'));

      expect(manifests, isNotEmpty, reason: 'At least one AndroidManifest.xml must exist');

      for (final manifest in manifests) {
        final content = manifest.readAsStringSync();
        expect(content.contains('com.example'), isFalse,
            reason: '${manifest.path} must not contain com.example');
      }
    });

    test('android/app/src source files (.kt and .java) do not contain com.example', () {
      final srcDir = Directory('android/app/src');
      expect(srcDir.existsSync(), isTrue);

      final sourceFiles = srcDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) {
            final p = f.path.replaceAll('\\', '/');
            return (p.endsWith('.kt') || p.endsWith('.java')) &&
                !p.endsWith('GeneratedPluginRegistrant.java');
          });

      expect(sourceFiles, isNotEmpty, reason: 'Android source files must exist');

      for (final srcFile in sourceFiles) {
        final content = srcFile.readAsStringSync();
        expect(content.contains('com.example'), isFalse,
            reason: '${srcFile.path} must not contain com.example');
      }

      // Verify MainActivity.kt exists under com/stardyai/app
      final mainActivity = File('android/app/src/main/kotlin/com/stardyai/app/MainActivity.kt');
      expect(mainActivity.existsSync(), isTrue,
          reason: 'MainActivity.kt must exist at android/app/src/main/kotlin/com/stardyai/app/MainActivity.kt');
      expect(mainActivity.readAsStringSync().contains('package com.stardyai.app'), isTrue,
          reason: 'MainActivity.kt must have package com.stardyai.app');
    });

    test('ios/Runner.xcodeproj/project.pbxproj uses com.stardyai.app and no com.example', () {
      final file = File('ios/Runner.xcodeproj/project.pbxproj');
      expect(file.existsSync(), isTrue, reason: 'project.pbxproj must exist');
      final content = file.readAsStringSync();

      expect(content.contains('com.example'), isFalse,
          reason: 'ios/Runner.xcodeproj/project.pbxproj must not contain com.example');

      // Runner targets
      final runnerMatches = RegExp(r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;]+);')
          .allMatches(content)
          .map((m) => m.group(1)!.trim())
          .toList();

      expect(runnerMatches, isNotEmpty, reason: 'Must find PRODUCT_BUNDLE_IDENTIFIER entries');

      final runnerIds = runnerMatches.where((id) => !id.contains('RunnerTests')).toList();
      expect(runnerIds, isNotEmpty, reason: 'Must find Runner PRODUCT_BUNDLE_IDENTIFIER entries');
      for (final id in runnerIds) {
        expect(id, equals('com.stardyai.app'),
            reason: 'Every Runner PRODUCT_BUNDLE_IDENTIFIER must be com.stardyai.app');
      }

      final testIds = runnerMatches.where((id) => id.contains('RunnerTests')).toList();
      expect(testIds, isNotEmpty, reason: 'Must find RunnerTests PRODUCT_BUNDLE_IDENTIFIER entries');
      for (final id in testIds) {
        expect(id, equals('com.stardyai.app.RunnerTests'),
            reason: 'Every RunnerTests PRODUCT_BUNDLE_IDENTIFIER must be com.stardyai.app.RunnerTests');
      }
    });
  });

  group('Firebase Options and Gradle Configuration Guard Tests (F8.0B)', () {
    test('(a) lib/firebase_options.dart must not contain com.example and must contain com.stardyai.app for android and ios', () {
      final file = File('lib/firebase_options.dart');
      expect(file.existsSync(), isTrue, reason: 'lib/firebase_options.dart must exist');
      final content = file.readAsStringSync();

      expect(content.contains('com.example'), isFalse,
          reason: 'lib/firebase_options.dart must not contain com.example');
      expect(content.contains('com.stardyai.app'), isTrue,
          reason: 'lib/firebase_options.dart must declare com.stardyai.app');

      // Check iOS bundle ID specifically
      expect(content.contains("iosBundleId: 'com.stardyai.app'"), isTrue,
          reason: 'lib/firebase_options.dart must configure iosBundleId: com.stardyai.app');
    });

    test('(b) lib/main.dart must call Firebase.initializeApp with the options argument', () {
      final file = File('lib/main.dart');
      expect(file.existsSync(), isTrue, reason: 'lib/main.dart must exist');
      final content = file.readAsStringSync();

      final plainCallRegex = RegExp(r'Firebase\.initializeApp\(\s*\)');
      expect(plainCallRegex.hasMatch(content), isFalse,
          reason: 'lib/main.dart must not call plain Firebase.initializeApp() without arguments');

      final optionsCallRegex = RegExp(r'Firebase\.initializeApp\(\s*options:\s*DefaultFirebaseOptions\.currentPlatform');
      expect(optionsCallRegex.hasMatch(content), isTrue,
          reason: 'lib/main.dart must call Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)');
    });

    test('(c) android/app/google-services.json must exist and its package_name must equal com.stardyai.app', () {
      final file = File('android/app/google-services.json');
      expect(file.existsSync(), isTrue, reason: 'android/app/google-services.json must exist');
      final content = file.readAsStringSync();

      final packageNameRegex = RegExp(r'"package_name":\s*"([^"]+)"');
      final match = packageNameRegex.firstMatch(content);
      expect(match, isNotNull, reason: 'google-services.json must contain package_name');
      expect(match!.group(1), equals('com.stardyai.app'),
          reason: 'package_name in google-services.json must equal com.stardyai.app');
    });

    test('(d) plugin com.google.gms.google-services must appear in both settings.gradle.kts and build.gradle.kts', () {
      final settingsFile = File('android/settings.gradle.kts');
      expect(settingsFile.existsSync(), isTrue, reason: 'android/settings.gradle.kts must exist');
      final settingsContent = settingsFile.readAsStringSync();
      expect(settingsContent.contains('com.google.gms.google-services'), isTrue,
          reason: 'android/settings.gradle.kts must declare com.google.gms.google-services');

      final buildFile = File('android/app/build.gradle.kts');
      expect(buildFile.existsSync(), isTrue, reason: 'android/app/build.gradle.kts must exist');
      final buildContent = buildFile.readAsStringSync();
      expect(buildContent.contains('com.google.gms.google-services'), isTrue,
          reason: 'android/app/build.gradle.kts must declare com.google.gms.google-services');
    });
  });
}

