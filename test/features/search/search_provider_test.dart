import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/search/providers/search_provider.dart';
import 'package:stardy_app/features/search/repository/search_repository.dart';

void main() {
  group('SearchNotifier 60-char maximum', () {
    test('search query > 60 chars is ignored', () async {
      int apiCalls = 0;
      final notifier = SearchNotifier<String>((query, {cursor}) async {
        apiCalls++;
        return Ok(SearchResult(items: ['Result'], nextCursor: null));
      });

      // 61 chars
      final longQuery = 'a' * 61;
      await notifier.search(longQuery);
      
      expect(apiCalls, 0);
      expect(notifier.state.isIdle, isTrue);
      expect(notifier.state.items, isNull);
    });

    test('search query <= 60 chars is executed', () async {
      int apiCalls = 0;
      final notifier = SearchNotifier<String>((query, {cursor}) async {
        apiCalls++;
        return Ok(SearchResult(items: ['Result'], nextCursor: null));
      });

      // 60 chars
      final query = 'a' * 60;
      await notifier.search(query);
      
      expect(apiCalls, 1);
      expect(notifier.state.isIdle, isFalse);
      expect(notifier.state.items, ['Result']);
    });
  });
}
