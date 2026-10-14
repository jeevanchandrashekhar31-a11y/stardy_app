import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';


import 'package:stardy_app/core/data/ttl_cache.dart';

void main() {
  group('TtlCache', () {
    test('set and get valid entry', () {
      DateTime currentTime = DateTime(2025, 1, 1);
      final cache = TtlCache(clock: () => currentTime);

      cache.set('key1', 'value1', const Duration(minutes: 5));
      expect(cache.get<String>('key1'), 'value1');
    });

    test('get expired entry returns null and removes it', () {
      DateTime currentTime = DateTime(2025, 1, 1);
      final cache = TtlCache(clock: () => currentTime);

      cache.set('key1', 'value1', const Duration(minutes: 5));

      // Advance time beyond expiry
      currentTime = currentTime.add(const Duration(minutes: 6));
      expect(cache.get<String>('key1'), isNull);
    });

    test('LRU eviction works when exceeding 100 entries', () {
      DateTime currentTime = DateTime(2025, 1, 1);
      final cache = TtlCache(clock: () => currentTime);

      for (int i = 0; i < 105; i++) {
        cache.set('key_$i', 'val_$i', const Duration(minutes: 5));
      }

      // First 5 should be evicted (LRU)
      expect(cache.get<String>('key_0'), isNull);
      expect(cache.get<String>('key_4'), isNull);
      // Last 100 should still be there
      expect(cache.get<String>('key_5'), 'val_5');
      expect(cache.get<String>('key_104'), 'val_104');
    });

    test('invalidate by prefix', () {
      DateTime currentTime = DateTime(2025, 1, 1);
      final cache = TtlCache(clock: () => currentTime);

      cache.set('user:1:profile', 'A', const Duration(minutes: 5));
      cache.set('user:1:settings', 'B', const Duration(minutes: 5));
      cache.set('user:2:profile', 'C', const Duration(minutes: 5));

      cache.invalidate('user:1:');

      expect(cache.get<String>('user:1:profile'), isNull);
      expect(cache.get<String>('user:1:settings'), isNull);
      expect(cache.get<String>('user:2:profile'), 'C');
    });

    test('clearAll', () {
      DateTime currentTime = DateTime(2025, 1, 1);
      final cache = TtlCache(clock: () => currentTime);

      cache.set('k1', 'v1', const Duration(minutes: 5));
      cache.set('k2', 'v2', const Duration(minutes: 5));

      cache.clearAll();
      expect(cache.get<String>('k1'), isNull);
      expect(cache.get<String>('k2'), isNull);
    });
  });

  group('CacheExtension (TTL Provider)', () {
    test('with no readers the provider disposes after the TTL; a read after the TTL refetches', () async {
      int createCalls = 0;
      int disposeCalls = 0;
      
      final testProvider = Provider.autoDispose<String>((ref) {
        createCalls++;
        ref.cacheFor(const Duration(milliseconds: 100));
        ref.onDispose(() {
          disposeCalls++;
        });
        return 'test_value_$createCalls';
      });

      final container = ProviderContainer();
      
      // No request is made when nobody reads
      expect(createCalls, 0);

      // Read it
      final sub = container.listen(testProvider, (_, _) {});
      expect(container.read(testProvider), 'test_value_1');
      expect(createCalls, 1);
      
      // Remove listener (so it becomes unread)
      sub.close();
      
      // Advance time by 120ms to exceed TTL
      await Future.delayed(const Duration(milliseconds: 150));
      
      // After TTL, with no active listeners, it should dispose
      expect(disposeCalls, 1, reason: 'provider should be disposed after TTL');
      
      // A subsequent read creates a new instance (refetches)
      expect(container.read(testProvider), 'test_value_2');
      expect(createCalls, 2, reason: 'read after TTL refetches');
      
      container.dispose();
    });
  });
}
