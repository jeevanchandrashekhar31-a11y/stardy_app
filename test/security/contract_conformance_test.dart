import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Contract conformance matrix is true and self-checking against repository and contract', () {
    final contractFile = File('docs/API_CONTRACT.md');
    expect(contractFile.existsSync(), isTrue, reason: 'docs/API_CONTRACT.md must exist');
    final contractLines = contractFile.readAsLinesSync();

    // Count endpoint lines in API_CONTRACT.md (e.g. "POST /auth/session", "GET /users/me")
    final endpointRegex = RegExp(r'^(GET|POST|PUT|DELETE|PATCH)\s+(\/[a-zA-Z0-9_\-\/:]+)');
    final contractEndpoints = contractLines
        .map((l) => l.trim())
        .where((l) => endpointRegex.hasMatch(l))
        .toList();

    expect(
      contractEndpoints.length,
      37,
      reason: 'docs/API_CONTRACT.md must contain exactly 37 endpoint definitions',
    );

    final matrixFile = File('docs/contract_conformance.md');
    expect(matrixFile.existsSync(), isTrue, reason: 'docs/contract_conformance.md must exist');
    final matrixLines = matrixFile.readAsLinesSync();

    // Find table rows starting with "| <digits> |"
    final rowRegex = RegExp(r'^\|\s*(\d+)\s*\|');
    final tableRows = matrixLines.where((l) => rowRegex.hasMatch(l.trim())).toList();

    expect(
      tableRows.length,
      contractEndpoints.length,
      reason: 'Number of matrix rows (${tableRows.length}) must match number of endpoints in API_CONTRACT.md (${contractEndpoints.length})',
    );

    // Collect all Dart files in lib/ for method existence check
    final libDir = Directory('lib');
    final libFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    final libContents = libFiles.map((f) => f.readAsStringSync()).toList();

    final failures = <String>[];

    for (final rawRow in tableRows) {
      final cols = rawRow.split('|').map((c) => c.trim()).toList();
      // cols[0] is empty, cols[1] is row #, cols[2] is Name, cols[3] is Method/Path,
      // cols[4] is Repo method, cols[5] is Fixture, cols[6] is Test file, cols[7] is Status
      final rowNum = cols[1];
      final endpointName = cols[2];
      final methodPath = cols[3];
      final repoMethodRaw = cols[4].replaceAll('`', '').replaceAll('*', '').trim();
      final fixtureRaw = cols[5].replaceAll('`', '').replaceAll('*', '').trim();
      final testFileRaw = cols[6].replaceAll('`', '').replaceAll('*', '').trim();
      final statusRaw = cols[7].replaceAll('*', '').trim();

      if (statusRaw == 'IMPLEMENTED') {
        // 1. Fixture file existence
        final fixtureFile = File(fixtureRaw);
        if (!fixtureFile.existsSync()) {
          failures.add('Row $rowNum ($endpointName - $methodPath): Cited fixture file "$fixtureRaw" does not exist.');
        }

        // 2. Test file existence
        final testFile = File(testFileRaw);
        if (!testFile.existsSync()) {
          failures.add('Row $rowNum ($endpointName - $methodPath): Cited test file "$testFileRaw" does not exist.');
        }

        // 3. Repository method existence in lib/
        final methodName = repoMethodRaw.contains('.')
            ? repoMethodRaw.split('.').last
            : repoMethodRaw;

        final methodExistsInLib = libContents.any((c) => c.contains(methodName));
        if (!methodExistsInLib) {
          failures.add('Row $rowNum ($endpointName - $methodPath): Repository method "$methodName" does not appear in lib/.');
        }

        // 4. Cited test file exercises the method and loads/mentions the fixture
        if (testFile.existsSync()) {
          final testContent = testFile.readAsStringSync();
          if (!testContent.contains(methodName)) {
            failures.add('Row $rowNum ($endpointName - $methodPath): Cited test file "$testFileRaw" does not contain method "$methodName".');
          }

          final fixtureFileName = fixtureRaw.split(RegExp(r'[/\\]')).last;
          if (!testContent.contains(fixtureFileName)) {
            failures.add('Row $rowNum ($endpointName - $methodPath): Cited test file "$testFileRaw" does not load/mention fixture "$fixtureFileName".');
          }
        }
      } else if (statusRaw == 'NOT USED BY CLIENT' || statusRaw == 'BLOCKED') {
        if (fixtureRaw != 'N/A') {
          failures.add('Row $rowNum ($endpointName - $methodPath): Non-implemented row must specify fixture "N/A", got "$fixtureRaw".');
        }
        if (testFileRaw != 'N/A') {
          failures.add('Row $rowNum ($endpointName - $methodPath): Non-implemented row must specify test file "N/A", got "$testFileRaw".');
        }
      } else {
        failures.add('Row $rowNum ($endpointName - $methodPath): Unknown status "$statusRaw". Expected IMPLEMENTED, NOT USED BY CLIENT, or BLOCKED.');
      }
    }

    if (failures.isNotEmpty) {
      fail('Contract conformance matrix verification failed with ${failures.length} errors:\n${failures.join('\n')}');
    }
  });
}
