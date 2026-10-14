import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ttlCacheProvider = Provider<TtlCache>((ref) {
  return TtlCache();
});

class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;
  _CacheEntry(this.value, this.expiresAt);
}

class TtlCache {
  final Map<String, _CacheEntry<dynamic>> _entries = {};
  final List<String> _lruKeys = [];
  final int _maxEntries = 100;

  DateTime Function() clock;

  TtlCache({DateTime Function()? clock})
    : clock = clock ?? (() => DateTime.now());

  void set<T>(String key, T value, Duration ttl) {
    if (_entries.containsKey(key)) {
      _lruKeys.remove(key);
    } else if (_entries.length >= _maxEntries) {
      final oldestKey = _lruKeys.removeAt(0);
      _entries.remove(oldestKey);
    }

    _lruKeys.add(key);
    _entries[key] = _CacheEntry<T>(value, clock().add(ttl));
  }

  T? get<T>(String key) {
    final entry = _entries[key];
    if (entry == null) return null;

    if (clock().isAfter(entry.expiresAt) ||
        clock().isAtSameMomentAs(entry.expiresAt)) {
      _entries.remove(key);
      _lruKeys.remove(key);
      return null;
    }

    _lruKeys.remove(key);
    _lruKeys.add(key);
    return entry.value as T;
  }

  void invalidate(String prefix) {
    final keysToRemove = _entries.keys
        .where((k) => k.startsWith(prefix))
        .toList();
    for (var k in keysToRemove) {
      _entries.remove(k);
      _lruKeys.remove(k);
    }
  }

  void clearAll() {
    _entries.clear();
    _lruKeys.clear();
  }
}

extension CacheExtension on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
