import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/state/paged_notifier.dart';
import 'package:stardy_app/core/models/page.dart' as model;

class TestItem {
  final String id;
  TestItem(this.id);
}

class TestPagedNotifier extends PagedNotifier<TestItem> {
  int fetchCallCount = 0;
  bool throwError = false;
  model.Page<TestItem>? mockResponse;

  @override
  Future<model.Page<TestItem>> fetchPage({
    String? cursor,
    int limit = 20,
  }) async {
    fetchCallCount++;
    if (throwError) throw Exception('Network Error');
    return mockResponse ?? const model.Page(items: []);
  }
}

void main() {
  group('PagedNotifier', () {
    test('first load success', () async {
      final notifier = TestPagedNotifier();
      notifier.mockResponse = model.Page(
        items: [TestItem('1'), TestItem('2')],
        nextCursor: 'next',
      );

      await notifier.loadFirst();

      expect(notifier.state.isLoading, false);
      expect(notifier.state.items.length, 2);
      expect(notifier.state.nextCursor, 'next');
      expect(notifier.state.hasMore, true);
    });

    test('load more appends items', () async {
      final notifier = TestPagedNotifier();
      // first load
      notifier.mockResponse = model.Page(
        items: [TestItem('1')],
        nextCursor: 'cursor_1',
      );
      await notifier.loadFirst();

      // load more
      notifier.mockResponse = model.Page(
        items: [TestItem('2')],
        nextCursor: null, // end of list
      );
      await notifier.loadMore();

      expect(notifier.state.items.length, 2);
      expect(notifier.state.items[1].id, '2');
      expect(notifier.state.nextCursor, isNull);
      expect(notifier.state.hasMore, false);
    });

    test('double loadMore sends one request (single-flight)', () async {
      final notifier = TestPagedNotifier();
      notifier.mockResponse = model.Page(
        items: [TestItem('1')],
        nextCursor: 'cursor_1',
      );
      await notifier.loadFirst();

      notifier.fetchCallCount = 0;

      // We need to stall the fetch to test single-flight.
      // But loadMore checks state.isLoading immediately synchronously.
      // Let's call loadMore twice without awaiting.
      final p1 = notifier.loadMore();
      final p2 = notifier.loadMore();
      await Future.wait([p1, p2]);

      expect(notifier.fetchCallCount, 1);
    });

    test('error keeps previous items', () async {
      final notifier = TestPagedNotifier();
      notifier.mockResponse = model.Page(
        items: [TestItem('1')],
        nextCursor: 'cursor_1',
      );
      await notifier.loadFirst();

      notifier.throwError = true;
      await notifier.loadMore();

      expect(notifier.state.error, contains('Something went wrong'));
      expect(notifier.state.items.length, 1); // items kept
    });

    test('refresh resets cursor and items', () async {
      final notifier = TestPagedNotifier();
      notifier.mockResponse = model.Page(
        items: [TestItem('1')],
        nextCursor: 'cursor_1',
      );
      await notifier.loadFirst();

      notifier.mockResponse = model.Page(
        items: [TestItem('A')],
        nextCursor: 'cursor_A',
      );
      await notifier.refresh();

      expect(notifier.state.items.length, 1);
      expect(notifier.state.items[0].id, 'A');
      expect(notifier.state.nextCursor, 'cursor_A');
    });
  });
}
