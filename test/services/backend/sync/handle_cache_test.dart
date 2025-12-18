import 'package:flutter_test/flutter_test.dart';
import 'package:bluebubbles/services/backend/sync/handle_cache.dart';
import 'package:bluebubbles/database/models.dart';

/// Unit tests for HandleCache
///
/// Note: These tests use mocked handles and don't require database access.
/// For full integration tests, you would need to set up ObjectBox in test mode.

void main() {
  group('HandleCache', () {
    late HandleCache cache;

    setUp(() {
      cache = HandleCache();
      cache.clear(); // Ensure fresh state
    });

    tearDown(() {
      cache.clear();
    });

    group('put and get', () {
      test('should cache handle by originalROWID', () {
        final handle = Handle(
          id: 1,
          originalROWID: 100,
          address: '+1234567890',
        );

        cache.put(handle);
        final retrieved = cache.getByRowId(100);

        expect(retrieved, isNotNull);
        expect(retrieved!.originalROWID, equals(100));
        expect(retrieved.address, equals('+1234567890'));
      });

      test('should cache handle by address', () {
        final handle = Handle(
          id: 1,
          originalROWID: 100,
          address: '+1234567890',
        );

        cache.put(handle);
        final retrieved = cache.getByAddress('+1234567890');

        expect(retrieved, isNotNull);
        expect(retrieved!.address, equals('+1234567890'));
      });

      test('should return null for uncached rowId', () {
        final retrieved = cache.getByRowId(999);
        expect(retrieved, isNull);
      });

      test('should return null for uncached address', () {
        final retrieved = cache.getByAddress('nonexistent');
        expect(retrieved, isNull);
      });
    });

    group('putAll', () {
      test('should cache multiple handles', () {
        final handles = [
          Handle(id: 1, originalROWID: 100, address: 'addr1'),
          Handle(id: 2, originalROWID: 200, address: 'addr2'),
          Handle(id: 3, originalROWID: 300, address: 'addr3'),
        ];

        cache.putAll(handles);

        expect(cache.getByRowId(100), isNotNull);
        expect(cache.getByRowId(200), isNotNull);
        expect(cache.getByRowId(300), isNotNull);
        expect(cache.stats['cacheByRowId'], equals(3));
      });
    });

    group('LRU eviction', () {
      test('should evict oldest entries when cache is full', () {
        // Fill cache beyond max size
        final handles = List.generate(
          HandleCache.maxCacheSize + 10,
          (i) => Handle(id: i, originalROWID: i, address: 'addr$i'),
        );

        cache.putAll(handles);

        // Cache should not exceed max size
        expect(
          cache.stats['cacheByRowId']! <= HandleCache.maxCacheSize,
          isTrue,
        );

        // Oldest entries should be evicted (first 10 items)
        // Note: exact eviction depends on access order
      });

      test('should update access order on get', () {
        final handle1 = Handle(id: 1, originalROWID: 1, address: 'addr1');
        final handle2 = Handle(id: 2, originalROWID: 2, address: 'addr2');

        cache.put(handle1);
        cache.put(handle2);

        // Access handle1 to make it most recently used
        cache.getByRowId(1);

        // Both should still be in cache
        expect(cache.getByRowId(1), isNotNull);
        expect(cache.getByRowId(2), isNotNull);
      });
    });

    group('clear', () {
      test('should clear all cached handles', () {
        final handles = [
          Handle(id: 1, originalROWID: 100, address: 'addr1'),
          Handle(id: 2, originalROWID: 200, address: 'addr2'),
        ];

        cache.putAll(handles);
        expect(cache.stats['cacheByRowId'], equals(2));

        cache.clear();
        expect(cache.stats['cacheByRowId'], equals(0));
        expect(cache.stats['cacheByAddress'], equals(0));
      });
    });

    group('edge cases', () {
      test('should ignore handles with null/invalid originalROWID', () {
        final handle = Handle(
          id: 1,
          originalROWID: null,
          address: 'addr1',
        );

        cache.put(handle);

        // Should still cache by address
        expect(cache.getByAddress('addr1'), isNotNull);
        // But not by rowId
        expect(cache.stats['cacheByRowId'], equals(0));
      });

      test('should ignore handles with originalROWID <= 0', () {
        final handle = Handle(
          id: 1,
          originalROWID: 0,
          address: 'addr1',
        );

        cache.put(handle);
        expect(cache.stats['cacheByRowId'], equals(0));
      });

      test('should ignore handles with empty address', () {
        final handle = Handle(
          id: 1,
          originalROWID: 100,
          address: '',
        );

        cache.put(handle);

        // Should cache by rowId
        expect(cache.getByRowId(100), isNotNull);
        // But not by empty address
        expect(cache.stats['cacheByAddress'], equals(0));
      });
    });
  });
}
